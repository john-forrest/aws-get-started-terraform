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
  imported_app_config  = jsondecode(data.aws_s3_bucket_object.app_config.body)
  imported_common_tags = data.aws_s3_bucket_object.common_tags.body
  imported_basename    = local.imported_app_config.basename

  basename = (var.basename != "") ? var.basename : local.imported_basename

  bucket_name_prefix = "${local.basename}-luvrs"

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "create-bucket"
  })
}

#############################################################################
# RESOURCES
#############################################################################

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

locals {
  bucket_name = "${local.bucket_name_prefix}-${random_integer.rand.result}"
}

resource "aws_s3_bucket" "pizza-luvrs" {
  bucket        = local.bucket_name
  acl           = "public-read"
  force_destroy = true

  # allow public read access to objects
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Action": [
          "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::pizza-luvrs-45770/*",
        "Principal": "*"
      }
    ]
  }
EOF

  # Allow cross-origin resource sharing since will be a different domain
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["Authorization"]
    max_age_seconds = 3000
  }

  tags = merge(local.common_tags,
    { name = local.bucket_name
  })
}

#############################################################################
# OUTPUTS
#############################################################################

output "bucket" {
  value = aws_s3_bucket.pizza-luvrs.bucket
}

output "bucket_name" {
  value = local.bucket_name
}
