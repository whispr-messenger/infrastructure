module "google_kubernetes_engine" {
  source = "git::https://github.com/whispr-messenger/infrastructure.git//terraform/modules/google_kubernetes_engine?ref=main"

  gcp_project_id   = var.gcp_project_id
  gke_cluster_name = var.gke_cluster_name
  gke_zone         = var.gke_zone
}