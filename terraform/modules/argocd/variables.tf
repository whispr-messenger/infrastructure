####################################################################################################
# Variables
####################################################################################################

variable "gke_cluster_name" {
  description = "GKE Cluster Name"
  default     = "whispr-cluster"
  type        = string
}
variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD (if empty, a random one will be generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_domain" {
  description = "Domain for accessing ArgoCD"
  default     = "argocd.whispr.epitech-msc2026.me"
  type        = string
}
