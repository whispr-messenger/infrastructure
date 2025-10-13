variable "argocd_namespace" {
  description = "Namespace where ArgoCD will be installed"
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
  type        = string
  default     = "argocd.whispr.epitech-msc2026.me"
}
