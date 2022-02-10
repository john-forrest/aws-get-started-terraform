terraform {
  backend "s3" {
    key = "applications/remote-state/terraform.tfstate"
  }
}
