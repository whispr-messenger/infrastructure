#####################################################################################################
# Outputs
#####################################################################################################

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.whispr.name
}

output "cluster_endpoint" {
  description = "The endpoint to access the GKE cluster"
  value       = google_container_cluster.whispr.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = google_container_cluster.whispr.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

