####################################################################################################
# OUTPUTS
####################################################################################################

output "namespace" {
  value = var.argocd_namespace
}


data "kubernetes_secret" "argocd_initial_admin_secret" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }
}

output "admin_password" {
  description = "Mot de passe admin ArgoCD"
  value       = nonsensitive(data.kubernetes_secret.argocd_initial_admin_secret.data["password"])
  sensitive   = false
}

output "server_url" {
  description = "URL du serveur ArgoCD"
  value       = "https://${var.argocd_domain}"
}