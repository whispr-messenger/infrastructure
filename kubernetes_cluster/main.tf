data "tfe_outputs" "whispr_gke" {
  organization = "glopez-personnal"
  workspace    = "whispr-google-kubernetes-engine"
}

module "kubernetes_cluster" {
  source = "git::https://github.com/whispr-messenger/infrastructure.git//terraform/modules/kubernetes_cluster?ref=main"

  gke_cluster_name      = data.tfe_outputs.whispr_gke.values.cluster_name
  argocd_domain         = "argocd.whispr.epitech-msc2026.me"
  argocd_namespace      = "argocd"
  argocd_admin_password = "" # If empty, a random one will be generated
}