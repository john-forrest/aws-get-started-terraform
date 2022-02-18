terraform {
  backend "s3" {
    key = "applications/bucket-content/terraform.tfstate"
  }
}
