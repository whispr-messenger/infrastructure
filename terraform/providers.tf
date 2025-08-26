####################################################################################################
# KUBERNETES PROVIDER
####################################################################################################
provider "kubernetes" {
  host                   = "https://${module.google_kubernetes_engine.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.google_kubernetes_engine.cluster_ca_certificate)
}

####################################################################################################
# HELM PROVIDER
####################################################################################################
provider "helm" {
  kubernetes {
    host                   = "https://${module.google_kubernetes_engine.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.google_kubernetes_engine.cluster_ca_certificate)
  }
}
