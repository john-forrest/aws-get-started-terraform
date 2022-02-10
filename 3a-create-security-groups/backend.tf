terraform {
  backend "s3" {
    key = "applications/create-security-groups/terraform.tfstate"
  }
}
