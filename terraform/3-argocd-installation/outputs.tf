output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = local.argocd_admin_password
  sensitive   = true
}

output "argocd_domain" {
  description = "ArgoCD domain"
  value       = var.argocd_domain
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = var.argocd_namespace
}

output "argocd_release_name" {
  description = "ArgoCD Helm release name"
  value       = helm_release.argocd.name
}
