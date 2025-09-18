output "argocd_namespace" {
  value = module.kubernetes_cluster.namespace
}

output "argocd_admin_password" {
  description = "Mot de passe admin ArgoCD"
  value       = nonsensitive(module.argocd.admin_password)
  sensitive   = false
}

output "argocd_server_url" {
  description = "URL du serveur ArgoCD"
  value       = module.argocd.server_url 
}