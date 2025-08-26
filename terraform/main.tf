
module "google_kubernetes_engine" {
  source = "./modules/gke"

  gcp_project_id   = var.gcp_project_id
  gke_cluster_name = var.gke_cluster_name
  gke_zone         = var.gke_zone
}

data "google_client_config" "default" {}

module "argocd" {
  source = "./modules/argocd"

  gke_cluster_name      = module.google_kubernetes_engine.cluster_name
  argocd_domain         = "argocd.whispr.epitech-msc2026.me"
  argocd_namespace      = "argocd"
  argocd_admin_password = "" # If empty, a random one will be generated

  depends_on = [module.google_kubernetes_engine]
}