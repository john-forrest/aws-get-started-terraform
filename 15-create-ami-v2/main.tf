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

variable "image_name" {
  type        = string
  description = "Name to use for image - default pizza-image"
  default     = ""
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

data "aws_s3_bucket_object" "app_config" {
  # Read config.json from the applications config bucket
  bucket = data.terraform_remote_state.applications_config.outputs.s3_bucket
  key    = "config.json"
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

  imported_app_config  = jsondecode(data.aws_s3_bucket_object.app_config.body)
  imported_common_tags = data.aws_s3_bucket_object.common_tags.body

  imported_basename = local.imported_app_config.basename

  basename   = (local.imported_basename != "") ? local.imported_basename : "pizza"
  image_name = (var.image_name != "") ? var.image_name : "${local.basename}-image"

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "create-ami"
  })
}

#############################################################################
# RESOURCES
#############################################################################

resource "aws_ami_from_instance" "pizza-image" {
  name               = local.image_name
  source_instance_id = local.imported-pizza-og-id

  tags = merge(local.common_tags, {
    Name = local.image_name
  })
}

#############################################################################
# OUTPUTS
#############################################################################

output "pizza-image-id" {
  value = aws_ami_from_instance.pizza-image.id
}

output "pizza-image-arn" {
  value = aws_ami_from_instance.pizza-image.arn
}
