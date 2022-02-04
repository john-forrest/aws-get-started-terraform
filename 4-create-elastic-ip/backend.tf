terraform {
  backend "s3" {
    key = "applications/create-elastic-ip/terraform.tfstate"
  }
}
