####################################################################################################
# Generate a random password if not provided
####################################################################################################
resource "random_password" "argocd_admin" {
  count   = var.argocd_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  argocd_admin_password = var.argocd_admin_password != "" ? var.argocd_admin_password : random_password.argocd_admin[0].result
}

####################################################################################################
# Create the namespace for ArgoCD
####################################################################################################

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
}

####################################################################################################
# Deploy ArgoCD using Helm
####################################################################################################

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.5.2" # Stable version at the time of writing
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout = 600

  # Custom values for ArgoCD
  values = [
    templatefile("${path.module}/values.yaml", {
      domain              = var.argocd_domain
      admin_password_hash = bcrypt(local.argocd_admin_password)
    })
  ]

  # Wait for the nodes to be ready
  wait          = true
  wait_for_jobs = true
}



