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

####################################################################################################
# Wait for ArgoCD CRDs to be available
####################################################################################################

# resource "null_resource" "wait_for_argocd_crds" {

#   provisioner "local-exec" {

#     interpreter = ["/bin/bash", "-c"]

#     command     = <<-EOF
#       set -euo pipefail

#       # Wait for ArgoCD to be ready
#       echo "Waiting for ArgoCD deployment to be ready..."
#       kubectl wait --for=condition=available deployment/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} --timeout=600s
#       kubectl wait --for=condition=available statefulset/argocd-application-controller -n ${kubernetes_namespace.argocd.metadata[0].name} --timeout=600s

#       # Wait for CRDs to be established
#       echo "Waiting for ArgoCD CRDs to be established..."
#       kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=300s
#       kubectl wait --for=condition=established crd/appprojects.argoproj.io --timeout=300s

#       echo "ArgoCD is ready!"
#     EOF

#     }

#   }

#   depends_on = [
#     helm_release.argocd,
#   ]
# }

####################################################################################################
# Create the root application in ArgoCD for the app of apps pattern
####################################################################################################
# resource "kubernetes_manifest" "root_app" {
#   manifest = yamldecode(file("${path.module}/app.yaml"))

#   depends_on = [null_resource.wait_for_argocd_crds]
# }



