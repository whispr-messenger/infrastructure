#####################################################################################################
# RESOURCES
#####################################################################################################

resource "google_compute_network" "vpc" {
  name                    = "${var.gke_cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.gke_cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Service Account
resource "google_service_account" "gke_sa" {
  account_id   = "${var.gke_cluster_name}-workers"
  display_name = "GKE Workers Service Account"
}

resource "google_project_iam_member" "gke_permissions" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ])
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Cluster GKE
resource "google_container_cluster" "whispr" {
  name     = var.gke_cluster_name
  location = var.gke_zone # Create a zonal cluster

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

resource "google_container_node_pool" "workers" {
  name     = "workers"
  location = var.gke_zone # Zonal cluster
  cluster  = google_container_cluster.whispr.name

  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"
    disk_size_gb = 50
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      machine-type = "e2-standard-4"
      node-count   = "3"
      preemptible  = "true"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

