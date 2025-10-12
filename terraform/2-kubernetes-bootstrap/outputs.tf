output "namespaces" {
  description = "Created Kubernetes namespaces"
  value = {
    argocd      = kubernetes_namespace.argocd.metadata[0].name
    postgresql  = kubernetes_namespace.postgresql.metadata[0].name
    redis       = kubernetes_namespace.redis.metadata[0].name
    sonarqube   = kubernetes_namespace.sonarqube.metadata[0].name
    whispr_prod = kubernetes_namespace.whispr_prod.metadata[0].name
  }
}

output "secrets" {
  description = "Created Kubernetes secrets"
  value = {
    argocd_secret     = kubernetes_secret.argocd_secret.metadata[0].name
    postgresql_secret = kubernetes_secret.postgresql_secret.metadata[0].name
    redis_secret      = kubernetes_secret.redis_secret.metadata[0].name
    sonarqube_secret  = kubernetes_secret.sonarqube_secret.metadata[0].name
    whispr_secrets    = kubernetes_secret.whispr_secrets.metadata[0].name
  }
}
