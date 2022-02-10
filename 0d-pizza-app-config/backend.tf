terraform {
  backend "s3" {
    key = "applications/config/terraform.tfstate"
  }
}
