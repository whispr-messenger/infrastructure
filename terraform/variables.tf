#####################################################################################################
# VARIABLES
#####################################################################################################

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gke_cluster_name" {
  description = "GKE Cluster Name"
  default     = "whispr-cluster"
  type        = string
}

variable "gke_zone" {
  description = "GKE Zone"
  default     = "europe-west1-b"
  type        = string
}

