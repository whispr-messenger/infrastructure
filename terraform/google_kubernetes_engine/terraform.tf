terraform {

  # Local backend — state stored in terraform.tfstate
  backend "local" {}

  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
