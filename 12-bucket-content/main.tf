##################################################################################
# VARIABLES
##################################################################################

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

##################################################################################
# PROVIDERS
##################################################################################

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

data "terraform_remote_state" "content-bucket" {
  # Get the bucket id
  backend = "s3"
  config = {
    bucket = var.applications_remote_state
    key    = "applications/create-bucket/terraform.tfstate" # must agree with backend.tf in create-bucket
    region = var.remote_state_region
  }
  # bucket will be data.terraform_remote_state.content-bucket.outputs.bucket
  # bucket_name will be data.terraform_remote_state.content-bucket.outputs.bucket_name
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

##################################################################################
# LOCALS
##################################################################################

locals {
  content_bucket = data.terraform_remote_state.content-bucket.outputs.bucket
  content_bucket_name = data.terraform_remote_state.content-bucket.outputs.bucket_name

  imported_app_config       = jsondecode(data.aws_s3_bucket_object.app_config.body)
  imported_common_tags      = data.aws_s3_bucket_object.common_tags.body
  imported_basename         = local.imported_app_config.basename

  basename         = (var.basename != "") ? var.basename : local.imported_basename

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "bucket-content"
  })
}

##################################################################################
# RESOURCES
##################################################################################


resource "aws_s3_bucket_object" "config_content" {
  for_each     = fileset("content/", "**")
  bucket       = local.content_bucket
  key          = each.value
  source       = "./content/${each.value}"
  # work out mimetype by matching suffix
  content_type = ((substr(each.value, -4, -1) == ".png") ? "image/png" : 
                  (substr(each.value, -3, -1) == ".js") ? "text/javascript" :
                  (substr(each.value, -5, -1) == ".json") ? "application/json" :
                  (substr(each.value, -4, -1) == ".css") ? "text/css" :
                  "binary/octet-stream")
  etag         = filemd5("./content/${each.value}") # will trigger new version if content update

  tags = merge(local.common_tags, {
    Name = "${local.content_bucket_name}-content-${each.value}"
  })
}

##################################################################################
# OUTPUT
##################################################################################


