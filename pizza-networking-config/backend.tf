terraform {
  backend "s3" {
    key = "networking/config/terraform.tfstate"
  }
}
