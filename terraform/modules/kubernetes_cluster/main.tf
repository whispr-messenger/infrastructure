# Create the namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      name = var.argocd_namespace
    }
  }
}

# Generate a random password if not provided
resource "random_password" "argocd_admin" {
  count   = var.argocd_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  argocd_admin_password = var.argocd_admin_password != "" ? var.argocd_admin_password : random_password.argocd_admin[0].result
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6" # Stable version at the time of writing
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout = 600

  # Custom values for ArgoCD
  values = [
    templatefile("${path.module}/values.yaml", {
      domain              = var.argocd_domain
      cluster_name        = var.gke_cluster_name
      admin_password_hash = bcrypt(var.argocd_admin_password)
    })
  ]

  # Wait for the nodes to be ready
  wait          = true
  wait_for_jobs = true
}

# Check if ArgoCD CRDs are available
data "kubernetes_resource" "argocd_application_crd" {
  api_version = "apiextensions.k8s.io/v1"
  kind        = "CustomResourceDefinition"
  
  metadata {
    name = "applications.argoproj.io"
  }

  depends_on = [
    helm_release.argocd,
    null_resource.wait_for_argocd_crds,
  ]
}

# Wait for ArgoCD CRDs to be available
resource "null_resource" "wait_for_argocd_crds" {
  provisioner "local-exec" {
    command = <<-EOF
      # Wait for ArgoCD to be ready
      echo "Waiting for ArgoCD deployment to be ready..."
      kubectl wait --for=condition=available deployment/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} --timeout=600s
      kubectl wait --for=condition=available deployment/argocd-application-controller -n ${kubernetes_namespace.argocd.metadata[0].name} --timeout=600s

      # Wait for CRDs to be established
      echo "Waiting for ArgoCD CRDs to be established..."
      kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=300s
      kubectl wait --for=condition=established crd/appprojects.argoproj.io --timeout=300s

      echo "ArgoCD is ready!"
    EOF
  }

  depends_on = [
    helm_release.argocd,
  ]
}

# Create the root application in ArgoCD for the app of apps pattern
resource "kubernetes_manifest" "root_app" {
  manifest = yamldecode(file("${path.module}/app.yaml"))

  depends_on = [
    helm_release.argocd,
    null_resource.wait_for_argocd_crds,
    data.kubernetes_resource.argocd_application_crd,
  ]
}



