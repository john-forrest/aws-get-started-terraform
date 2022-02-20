terraform {
  backend "s3" {
    key = "applications/autoscale/terraform.tfstate"
  }
}
