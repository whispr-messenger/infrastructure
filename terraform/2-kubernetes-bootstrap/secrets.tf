resource "kubernetes_secret" "argocd_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  type = "Opaque"

  data = {
    "admin.password"    = var.argocd_admin_password
    "server.secretkey" = var.argocd_secret_key
  }
}

resource "kubernetes_secret" "postgresql_secret" {
  metadata {
    name      = "postgresql-secret"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
  }

  type = "Opaque"

  data = {
    "postgres-password" = var.postgres_password
    "password"          = var.postgres_password
    "username"          = var.postgres_user
    "database"          = var.postgres_db
  }
}

resource "kubernetes_secret" "redis_secret" {
  metadata {
    name      = "redis-secret"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  type = "Opaque"

  data = {
    "redis-password" = var.redis_password
  }
}

resource "kubernetes_secret" "sonarqube_secret" {
  metadata {
    name      = "sonarqube-secret"
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
  }

  type = "Opaque"

  data = {
    "jdbc-password"  = var.sonarqube_jdbc_password
    "admin-password" = var.sonarqube_admin_password
  }
}

resource "kubernetes_secret" "whispr_secrets" {
  metadata {
    name      = "whispr-secrets"
    namespace = kubernetes_namespace.whispr_prod.metadata[0].name
  }

  type = "Opaque"

  data = {
    "jwt-secret"              = var.jwt_secret
    "database-url"            = var.database_url
    "redis-url"               = var.redis_url
    "aws-access-key-id"       = var.aws_access_key_id
    "aws-secret-access-key"   = var.aws_secret_access_key
    "aws-region"              = var.aws_region
    "smtp-host"               = var.smtp_host
    "smtp-port"               = var.smtp_port
    "smtp-user"               = var.smtp_user
    "smtp-password"           = var.smtp_password
    "encryption-key"          = var.encryption_key
  }
}
