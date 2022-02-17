terraform {
  backend "s3" {
    key = "applications/create-bucket/terraform.tfstate"
  }
}
