terraform {
  cloud {
    organization = "whispr-messenger"

    workspaces {
      name = "1-gcp-infrastructure"
    }
  }
}
