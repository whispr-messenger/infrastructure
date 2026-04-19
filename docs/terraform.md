# Terraform

## Infrastructure as Code

Le cluster GKE est provisionné via Terraform.

## Modules

| Module | Rôle |
|--------|------|
| `google_kubernetes_engine` | Provisioning du cluster GKE |
| `kubernetes_cluster` | Configuration du cluster K8s |

## Cluster GKE

```
┌─────────────────────────────┐
│   GCP Project               │
│   tranquil-harbor-480911-k9 │
│                             │
│  ┌───────────────────────┐  │
│  │  GKE Cluster          │  │
│  │  whispr-messenger     │  │
│  │  Region: europe-west1 │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

## Usage

```bash
cd terraform/google_kubernetes_engine
terraform init
terraform plan
terraform apply
```
