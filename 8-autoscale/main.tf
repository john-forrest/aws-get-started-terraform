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
  # The security group id (pizza-ec2-sg) will be data.terraform_remote_state.pizza-og.outputs.ec2-sg-id
}

data "terraform_remote_state" "pizza-ami" {
  # Get id of the pizza-og instance
  backend = "s3"
  config = {
    bucket = var.applications_remote_state
    key    = "applications/create-ami/terraform.tfstate" # must agree with backend.tf in create-ec2-instance
    region = var.remote_state_region
  }
  # The id will be data.terraform_remote_state.pizza-ami.outputs.pizza-image-id
}

data "terraform_remote_state" "load-balancer" {
  # Get id of the pizza-og instance
  backend = "s3"
  config = {
    bucket = var.applications_remote_state
    key    = "applications/app-load-balancer/terraform.tfstate" # must agree with backend.tf in create-load-balancer
    region = var.remote_state_region
  }
  # target group arns will be data.terraform_remote_state.load-balancer.outputs.pizza-loader-tg-arns
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
  public_subnets    = data.terraform_remote_state.setup_vpc.outputs.public_subnets
  pizza-ec2-sg-id   = data.terraform_remote_state.pizza-og.outputs.ec2-sg-id
  target_group_arns = data.terraform_remote_state.load-balancer.outputs.pizza-loader-tg-arns
  image-id          = data.terraform_remote_state.pizza-ami.outputs.pizza-image-id

  imported_app_config  = jsondecode(data.aws_s3_bucket_object.app_config.body)
  imported_common_tags = data.aws_s3_bucket_object.common_tags.body
  imported_basename    = local.imported_app_config.basename

  basename = (local.imported_basename != "") ? local.imported_basename : "pizza"

  template_name          = "${local.basename}-lt"
  template_instance_name = "${local.template_name}-instance"
  asg_name               = "${local.basename}-asg"
  asg-policy-name        = "${local.basename}-asg-pol"

  common_tags = merge(jsondecode(local.imported_common_tags), {
    module = "autoscale"
  })
}

#############################################################################
# RESOURCES
#############################################################################

resource "aws_launch_template" "pizza-lt" {
  name = local.template_name

  image_id = local.image-id

  instance_type = "t2.micro"

  network_interfaces {
    security_groups = [local.pizza-ec2-sg-id] # "pizza-ec2-sg"
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "starting pizza-luvrs"
cd /home/ec2-user/pizza-luvrs
npm start
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = local.template_instance_name
    })
  }

  tags = merge(local.common_tags, {
    Name = local.template_name
  })
}

resource "aws_autoscaling_group" "pizza-asg" {
  name = local.asg_name

  launch_template {
    id      = aws_launch_template.pizza-lt.id
    version = aws_launch_template.pizza-lt.latest_version
  }

  target_group_arns   = local.target_group_arns
  vpc_zone_identifier = local.public_subnets

  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  # tag/tags for this resource has a special feature and is not the same as
  # other aws resources. Best leave unset.
}

resource "aws_autoscaling_policy" "pizza-asg-pol" {
  name = local.asg-policy-name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkOut"
    }

    target_value = 50000
  }

  autoscaling_group_name = aws_autoscaling_group.pizza-asg.name
}

#############################################################################
# OUTPUTS
#############################################################################



