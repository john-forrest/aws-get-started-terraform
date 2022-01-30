#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "network_remote_state" {
  type        = string
  description = "Bucket that contains the remote state for networking/config/terraform.tfstate"
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
  profile = "infra"
}

#############################################################################
# DATA SOURCES
#############################################################################

data "aws_availability_zones" "azs" {}

data "terraform_remote_state" "network_config" {
  backend = "s3"
  config = {
    bucket = var.network_remote_state
    key    = "networking/config/terraform.tfstate" # must agree with backend.tf in pizza-networking-config
    region = var.remote_state_region
  }
  # The bucket with be data.terraform_remote_state.network_config.s3_bucket
}

data "aws_s3_bucket_object" "vpc_config" {
  bucket = data.terraform_remote_state.network_config.outputs.s3_bucket
  key    = "pizza-vpc.json"
}

data "aws_s3_bucket_object" "common_tags" {
  bucket = data.terraform_remote_state.network_config.outputs.s3_bucket
  key    = "common_tags.json"
}

#############################################################################
# LOCALS
#############################################################################

locals {
  imported_vpc_config   = data.aws_s3_bucket_object.vpc_config.body
  imported_common_tags  = data.aws_s3_bucket_object.common_tags.body
  vpc_cidr_block        = jsondecode(local.imported_vpc_config)["cidr_block"]
  vpc_subnet_count      = jsondecode(local.imported_vpc_config)["subnet_count"]
  vpc_subnet_extra_bits = lookup(jsondecode(local.imported_vpc_config), "subnet_bits", 8)
  common_tags = merge(jsondecode(local.imported_common_tags), {
    "module" : "setup-vpc"
  })
}

#############################################################################
# RESOURCES
#############################################################################  

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "pizza-vpc"
  cidr = local.vpc_cidr_block

  azs = slice(data.aws_availability_zones.azs.names, 0, (local.vpc_subnet_count))
  public_subnets = [for subnet in range(local.vpc_subnet_count) :
  cidrsubnet(local.vpc_cidr_block, local.vpc_subnet_extra_bits, subnet)]

  tags = merge(local.common_tags, {
    Environment = "dev"
    Team        = "infra"
    # Name        = "pizza-vpc" # make compat with self.name
  })

}

#############################################################################
# OUTPUTS
#############################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}


