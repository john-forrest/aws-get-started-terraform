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

variable "basename" {
  type        = string
  description = "Base to use for names - default comes from config.json"
  default     = ""
}

variable "role_name" {
  type        = string
  description = "Name to use for role - default appends -ec2-role to basename"
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

data "aws_iam_policy" "AmazonS3FullAccess" {
  name = "AmazonS3FullAccess"
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
  imported_app_config       = jsondecode(data.aws_s3_bucket_object.app_config.body)
  imported_common_tags      = data.aws_s3_bucket_object.common_tags.body
  imported_basename         = local.imported_app_config.basename
  imported_policy           = data.aws_iam_policy.AmazonS3FullAccess.policy
  
  managed_policy_arns = [data.aws_iam_policy.AmazonS3FullAccess.arn]
  
  basename         = (var.basename != "") ? var.basename : local.imported_basename
  role_name        = (var.role_name != "") ? var.role_name : "${local.basename}-ec2-role"

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "ec2-role"
  })
}

#############################################################################
# RESOURCES
#############################################################################

resource "aws_iam_role" "pizza-ec2-role" {
  name                = local.role_name
  # default role policy
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	  {
		  "Effect": "Allow",
		  "Principal": {
			  "Service": "ec2.amazonaws.com"
		  },
		  "Action": "sts:AssumeRole"
	  }
  ]
}
EOF

  managed_policy_arns = local.managed_policy_arns
  
  tags = merge(local.common_tags, {
    Name = local.role_name
  })
}

resource "aws_iam_instance_profile" "pizza-ec2-role-profile" {
  name = local.role_name
  role = aws_iam_role.pizza-ec2-role.id

  tags = merge(local.common_tags, {
    Name = local.role_name
  })
}

#############################################################################
# OUTPUTS
#############################################################################

output "pizza-ec2-role-id" {
  value = aws_iam_role.pizza-ec2-role.id
}

output "pizza-ec2-role-arn" {
  value = aws_iam_role.pizza-ec2-role.arn
}

output "pizza-ec2-role-unique-id" {
  value = aws_iam_role.pizza-ec2-role.unique_id
}

output "pizza-ec2-role-profile-name" {
  value = aws_iam_instance_profile.pizza-ec2-role-profile.name
}

output "pizza-ec2-role-profile-arn" {
  value = aws_iam_instance_profile.pizza-ec2-role-profile.arn
}
