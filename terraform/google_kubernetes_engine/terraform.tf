terraform {

  # Use Terraform Cloud as the backend to store the state file
  backend "remote" {
    organization = "glopez-personnal"

    workspaces {
      name = "whispr-google-kubernetes-engine"
    }
  }

  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
