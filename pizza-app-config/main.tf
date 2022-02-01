##################################################################################
# VARIABLES
##################################################################################

variable "region" {
  type    = string
  default = "us-east-1"
}

#Bucket variables
variable "aws_bucket_prefix" {
  type    = string
  default = "pizza-applications-config"
}

variable "full_access_users" {
  type    = list(string)
  default = []

}

variable "read_only_users" {
  type    = list(string)
  default = []
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

##################################################################################
# LOCALS
##################################################################################

locals {
  common_tags = jsondecode(file("configs/common_tags.json"))
}

##################################################################################
# RESOURCES
##################################################################################

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

locals {
  bucket_name = "${var.aws_bucket_prefix}-${random_integer.rand.result}"
}

module "protected_s3_bucket" {
  source = "../modules/protected-s3-bucket"

  bucket_name       = local.bucket_name
  full_access_users = var.full_access_users
  read_only_users   = var.read_only_users
  common_tags       = local.common_tags
}


##################################################################################
# Bucket Objects
##################################################################################

resource "aws_s3_bucket_object" "config_content" {
  for_each     = fileset("configs/", "*.json")
  bucket       = module.protected_s3_bucket.bucket
  key          = each.value
  source       = "./configs/${each.value}"
  content_type = "application/json"
  etag         = filemd5("./configs/${each.value}") # will trigger new version if content update

  tags = merge(local.common_tags, {
    Name = "${local.bucket_name}-configs-${each.value}"
  })
}

##################################################################################
# OUTPUT
##################################################################################

output "s3_bucket" {
  value = module.protected_s3_bucket.bucket
}
