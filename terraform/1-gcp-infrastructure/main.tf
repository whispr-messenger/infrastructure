terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

module "gke_cluster" {
  source = "../modules/google_kubernetes_engine"

  gcp_project_id   = var.gcp_project_id
  gke_zone         = var.gke_zone
  gke_cluster_name = var.gke_cluster_name
}
