output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.google_kubernetes_engine.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint to access the GKE cluster"
  value       = module.google_kubernetes_engine.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = module.google_kubernetes_engine.cluster_ca_certificate
  sensitive   = true
}

output "access_token" {
  description = "The access token for the GCP client"
  value       = data.google_client_config.default.access_token
  sensitive   = true
}