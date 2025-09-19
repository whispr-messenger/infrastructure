terraform {

  # Use Terraform Cloud as the backend to store the state file
  backend "remote" {
    organization = "glopez-personnal"

    workspaces {
      name = "whispr-kubernetes-cluster"
    }
  }

  required_version = ">= 1.6"
}
