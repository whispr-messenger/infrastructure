####################################################################################################
# OUTPUTS
####################################################################################################

data "kubernetes_secret" "argocd_initial_admin_secret" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"
  }
}

output "argocd_admin_password" {
  description = "Mot de passe admin ArgoCD"
  value       = nonsensitive(data.kubernetes_secret.argocd_initial_admin_secret.data["admin.password"])
  sensitive   = false
}

output "argocd_server_url" {
  description = "URL du serveur ArgoCD"
  value       = "https://${var.argocd_domain}"
}