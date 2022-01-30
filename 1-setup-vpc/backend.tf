terraform {
    backend "s3" {
        key = "networking/vpc/terraform.tfstate"
    }
}
