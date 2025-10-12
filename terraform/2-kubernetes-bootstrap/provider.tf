data "terraform_remote_state" "gcp_infra" {
  backend = "remote"

  config = {
    organization = "whispr-messenger"
    workspaces = {
      name = "1-gcp-infrastructure"
    }
  }
}

provider "google" {
  project = data.terraform_remote_state.gcp_infra.outputs.gcp_project_id
  region  = "europe-west1"
}

data "google_client_config" "default" {}

data "google_container_cluster" "cluster" {
  name     = data.terraform_remote_state.gcp_infra.outputs.cluster_name
  location = data.terraform_remote_state.gcp_infra.outputs.gke_zone
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}
