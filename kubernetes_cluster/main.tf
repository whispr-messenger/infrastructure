data "google_client_config" "default" {}

module "kubernetes_cluster" {
  source = "../terraform/modules/kubernetes_cluster"

  gke_cluster_name      = var.gke_cluster_name
  argocd_domain         = "argocd.whispr.epitech-msc2026.me"
  argocd_namespace      = "argocd"
  argocd_admin_password = "" # If empty, a random one will be generated
}