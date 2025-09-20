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