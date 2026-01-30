# Retrieve outputs from the GKE workspace
data "tfe_outputs" "whispr_gke" {
  organization = "glopez-personnal"
  workspace    = "whispr-google-kubernetes-engine"
}

# Retrieve a fresh authentication token as the one stored in the other workspace state file may be expired
data "google_client_config" "default" {}

module "kubernetes_cluster" {
  source = "git::https://github.com/whispr-messenger/infrastructure.git//terraform/modules/kubernetes_cluster?ref=main"

  gke_cluster_name      = data.tfe_outputs.whispr_gke.values.cluster_name
  argocd_domain         = "argocd.whispr.fr"
  argocd_admin_password = "" # If empty, a random one will be generated
}