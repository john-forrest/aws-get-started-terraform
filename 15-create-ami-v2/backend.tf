terraform {
  backend "s3" {
    key = "applications/create-ami/terraform.tfstate"
  }
}
