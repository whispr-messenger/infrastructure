module "google_kubernetes_engine" {
  source = "../terraform/modules/google_kubernetes_engine"

  gcp_project_id   = var.gcp_project_id
  gke_cluster_name = var.gke_cluster_name
  gke_zone         = var.gke_zone
}