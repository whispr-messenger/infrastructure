data "google_client_config" "default" {}

data "terraform_remote_state" "gke" {
  backend = "remote"
  config = {
    organization = "glopez-personnal"
    workspaces = {
      name = "whispr-google-kubernetes-engine"
    }
  }
}

module "kubernetes_cluster" {
  source = "git::https://github.com/whispr-messenger/infrastructure.git//terraform/modules/kubernetes_cluster?ref=main"

  gke_cluster_name      = data.terraform_remote_state.gke.cluster_name
  argocd_domain         = "argocd.whispr.epitech-msc2026.me"
  argocd_namespace      = "argocd"
  argocd_admin_password = "" # If empty, a random one will be generated
}