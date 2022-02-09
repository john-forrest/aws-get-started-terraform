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

variable "port_number" {
  type        = number
  description = "Port load balancer will forward to instances on (default 3000)"
  default     = 0
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
  public_subnets = data.terraform_remote_state.setup_vpc.outputs.public_subnets
  vpc_id         = data.terraform_remote_state.setup_vpc.outputs.vpc_id
  pizza-og-id    = data.terraform_remote_state.pizza-og.outputs.instance-id

  imported_instance_config = data.aws_s3_bucket_object.instance_config.body
  imported_common_tags     = data.aws_s3_bucket_object.common_tags.body

  imported_port_number = jsondecode(local.imported_instance_config)["port_number"]
  imported_basename    = jsondecode(local.imported_instance_config)["basename"]

  port_number = (var.port_number != 0) ? var.port_number : local.imported_port_number

  basename = (local.imported_basename != "") ? local.imported_basename : "pizza"

  loader_name    = "${local.basename}-loader"
  loader_sg_name = "${local.basename}-lb-sg"

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "create-loadbalancer"
  })
}

#############################################################################
# RESOURCES
#############################################################################

module "pizza-lb-sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~>4.0"

  name        = local.loader_sg_name
  description = "Security group for ${local.basename}-lb - allow any access on port 80"
  vpc_id      = local.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = merge(local.common_tags, {
    Name = local.loader_sg_name
  })
  # specific output: security_group_id
}

module "pizza-loader" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = local.loader_name

  load_balancer_type = "application"

  vpc_id          = local.vpc_id
  subnets         = local.public_subnets
  security_groups = [module.pizza-lb-sg.security_group_id]

  target_groups = [
    {
      name             = "${local.loader_name}-tg"
      backend_protocol = "HTTP"
      backend_port     = local.port_number
      target_type      = "instance"
      targets = [
        {
          target_id = local.pizza-og-id
          port      = local.port_number # seems this is required even though it seems redundant
        }
      ]
      health_check = {
        protocol = "HTTP"
        path     = "/"
      }
      stickiness = {
        type = "lb_cookie" # defaults to one day timeout
      }
      tags = merge(local.common_tags, {
        Name = "${local.loader_name}-tg"
      })
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = merge(local.common_tags, {
    Name = local.loader_name
  })
}

#############################################################################
# OUTPUTS
#############################################################################

output "pizza-lb-sg-id" {
  value = module.pizza-lb-sg.security_group_id
}

output "pizza-loader-id" {
  value = module.pizza-loader.lb_id
}

output "pizza-loader-tg-arns" {
  value = module.pizza-loader.target_group_arns
}

output "pizza-loader-tg-attachments" {
  value = module.pizza-loader.target_group_attachments
}

output "pizza-loader-dns-name" {
  value = module.pizza-loader.lb_dns_name
}

