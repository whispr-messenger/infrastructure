variable "cluster_name" {
  description = "GKE Cluster Name"
  default     = "whispr-cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "GKE Cluster CA Certificate"
  type        = string
}