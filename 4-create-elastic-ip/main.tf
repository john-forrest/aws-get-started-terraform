#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type    = string
  default = "us-east-1"
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

data "terraform_remote_state" "pizza-og" {
  # Get id of the pizza-og instance
  backend = "s3"
  config = {
    bucket = var.applications_remote_state
    key    = "applications/create-pizza-og/terraform.tfstate" # must agree with backend.tf in create-ec2-instance
    region = var.remote_state_region
  }
  # The id will be data.terraform_remote_state.pizza-og.outputs.instance-id
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

#############################################################################
# LOCALS
#############################################################################

locals {
  imported-pizza-og-id = data.terraform_remote_state.pizza-og.outputs.instance-id
  
  imported_instance_config = data.aws_s3_bucket_object.instance_config.body
  imported_common_tags     = data.aws_s3_bucket_object.common_tags.body

  imported_basename      = jsondecode(local.imported_instance_config)["basename"]

  basename                = (local.imported_basename != "") ? local.imported_basename : "pizza"
  eip_name                = "${local.basename}-og-eip"

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "create-elastic-ip"
  })
}

#############################################################################
# RESOURCES
#############################################################################  

resource "aws_eip" "pizza-og-eip" {
  instance = local.imported-pizza-og-id
  vpc      = true

  tags = merge(local.common_tags, {
    Name = local.eip_name
  })
}

#############################################################################
# OUTPUTS
#############################################################################

output "pizza-og-eip" {
  value = aws_eip.pizza-og-eip.public_ip
}
