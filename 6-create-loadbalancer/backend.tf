terraform {
  backend "s3" {
    key = "applications/app-load-balancer/terraform.tfstate"
  }
}
