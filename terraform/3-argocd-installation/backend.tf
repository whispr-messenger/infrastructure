terraform {
  cloud {
    organization = "whispr-messenger"

    workspaces {
      name = "3-argocd-installation"
    }
  }
}
