variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gke_zone" {
  description = "GKE Zone"
  type        = string
  default     = "europe-west1-b"
}

variable "gke_cluster_name" {
  description = "GKE Cluster Name"
  type        = string
  default     = "whispr-cluster"
}
