terraform {

  backend "remote" {
    organization = "whispr-messenger"

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
