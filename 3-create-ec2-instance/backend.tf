terraform {
  backend "s3" {
    key = "applications/create-pizza-og/terraform.tfstate"
  }
}
