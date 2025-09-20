####################################################################################################
# KUBERNETES PROVIDER
####################################################################################################
provider "kubernetes" {
  host                   = "https://${data.tfe_outputs.whispr_gke.values.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.tfe_outputs.whispr_gke.values.cluster_ca_certificate)
}

####################################################################################################
# HELM PROVIDER
####################################################################################################
provider "helm" {
  kubernetes {
    host                   = "https://${data.tfe_outputs.whispr_gke.values.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.tfe_outputs.whispr_gke.values.cluster_ca_certificate)
  }
}
