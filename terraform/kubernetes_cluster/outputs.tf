output "argocd_admin_password" {
  description = "Mot de passe admin ArgoCD"
  value       = nonsensitive(module.kubernetes_cluster.argocd_admin_password)
  sensitive   = false
}

output "argocd_server_url" {
  description = "URL du serveur ArgoCD"
  value       = module.kubernetes_cluster.argocd_server_url
}
