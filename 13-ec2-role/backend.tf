terraform {
  backend "s3" {
    key = "applications/ec2-role/terraform.tfstate"
  }
}
