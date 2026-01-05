terraform {
  cloud {
    organization = "whispr-messenger"

    workspaces {
      name = "2-kubernetes-bootstrap"
    }
  }
}
