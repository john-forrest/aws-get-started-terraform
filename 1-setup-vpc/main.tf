#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
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

#############################################################################
# RESOURCES
#############################################################################  

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "pizza-vpc"
  cidr = var.vpc_cidr_range

  azs            = slice(data.aws_availability_zones.azs.names, 0, 2)
  public_subnets = var.public_subnets

  map_public_ip_on_launch = false

  tags = {
    Environment = "dev"
    Team        = "infra"
	# Name        = "pizza-vpc" # make compat with self.name
  }

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


