#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "network_remote_state" {
  type        = string
  description = "Bucket that contains the remote state for networking/*/terraform.tfstate"
}

variable "applications_remote_state" {
  type        = string
  description = "Bucket that contains the remote state for applications/*/terraform.tfstate"
}

variable "remote_state_region" {
  type        = string
  description = "Region where network_remote_state bucket is sited"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Instance-type to use for EC2 - default typically t2.micro but comes from config file"
  default     = ""
}

variable "port_number" {
  type        = number
  description = "Port number of application - default typically 3000 but comes from config file"
  default     = 0
}

variable "key_pair" {
  type        = string
  description = "EC2 key pair to use for ssh"
  default     = "pizza-keys"
}

variable "instance_name" {
  type    = string
  default = "" # will default to "${basename}-og" or "pizza-og"
}

#############################################################################
# PROVIDERS
#############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "app"
}

#############################################################################
# DATA SOURCES
#############################################################################

data "aws_availability_zones" "azs" {}

data "terraform_remote_state" "applications_config" {
  # Get bucket where we store the applications config
  backend = "s3"
  config = {
    bucket = var.applications_remote_state
    key    = "applications/config/terraform.tfstate" # must agree with backend.tf in pizza-applications-config
    region = var.remote_state_region
  }
  # The bucket will be data.terraform_remote_state.applications_config.outputs.s3_bucket
}

data "terraform_remote_state" "setup_vpc" {
  # Get the vpc and (in particular) subnet info from the setup-vpc module(s)
  backend = "s3"
  config = {
    bucket = var.network_remote_state
    key    = "networking/vpc/terraform.tfstate" # must agree with backend.tf in setup-vpc
    region = var.remote_state_region
  }
  # public_subnets will be data.terraform_remote_state.setup_vpc.outputs.public_subnets
}

data "terraform_remote_state" "create-security-groups" {
  # Get the vpc and (in particular) subnet info from the setup-vpc module(s)
  backend = "s3"
  config = {
    bucket = var.applications_remote_state
    key    = "applications/create-security-groups/terraform.tfstate" # must agree with backend.tf in create-security-groups
    region = var.remote_state_region
  }
  # pizza-ec2-sg will be data.terraform_remote_state.create-security-groups.outputs.ec2-sg-id
  # pizza-ec2-ssh will be data.terraform_remote_state.create-security-groups.outputs.ec2-ssh-id
}

data "aws_s3_bucket_object" "instance_config" {
  # Read instance.json from the applications config bucket
  bucket = data.terraform_remote_state.applications_config.outputs.s3_bucket
  key    = "instance.json"
}

data "aws_s3_bucket_object" "common_tags" {
  # Read common_tags.json from the applications config bucket
  bucket = data.terraform_remote_state.applications_config.outputs.s3_bucket
  key    = "common_tags.json"
}

data "aws_ami" "aws_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  # image id is data.aws_ami.aws_linux.id
}

#############################################################################
# LOCALS
#############################################################################

locals {
  public_subnets = data.terraform_remote_state.setup_vpc.outputs.public_subnets
  vpc_id         = data.terraform_remote_state.setup_vpc.outputs.vpc_id

  pizza-ec2-sg     = data.terraform_remote_state.create-security-groups.outputs.ec2-sg-id
  pizza-ec2-ssh-sg = data.terraform_remote_state.create-security-groups.outputs.ec2-ssh-id

  imported_instance_config = data.aws_s3_bucket_object.instance_config.body
  imported_common_tags     = data.aws_s3_bucket_object.common_tags.body

  imported_instance_type = jsondecode(local.imported_instance_config)["instance_type"]
  imported_port_number   = jsondecode(local.imported_instance_config)["port_number"]
  imported_basename      = jsondecode(local.imported_instance_config)["basename"]

  instance_type = (var.instance_type != "") ? var.instance_type : local.imported_instance_type
  port_number   = (var.port_number != 0) ? var.port_number : local.imported_port_number

  basename                = (local.imported_basename != "") ? local.imported_basename : "pizza"
  sg_security_group_name  = "${local.basename}-ec2-sg"                                             # pizza-ec2-sg
  ssh_security_group_name = "${local.basename}-ec2-ssh"                                            # pizza-ec2-ssh
  instance_name           = (var.instance_name != "") ? var.instance_name : "${local.basename}-og" # usually pizza-og

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "create-ec2-instance"
  })
}

#############################################################################
# RESOURCES
#############################################################################  

resource "aws_instance" "pizza-og" {
  ami           = data.aws_ami.aws_linux.id
  instance_type = local.instance_type
  subnet_id     = local.public_subnets[0]
  vpc_security_group_ids = [
    local.pizza-ec2-sg,
    local.pizza-ec2-ssh-sg # to allow remote ssh access to this instance
  ]
  key_name                    = var.key_pair
  associate_public_ip_address = false

  tags = merge(local.common_tags, {
    Name = local.instance_name
  })
}

#############################################################################
# OUTPUTS
#############################################################################

output "ec2-sg-id" {
  value = local.pizza-ec2-sg
}

output "instance-id" {
  value = aws_instance.pizza-og.id
}
