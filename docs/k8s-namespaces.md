# Namespaces Kubernetes

## Organisation

Le cluster est organisé en namespaces pour isoler les différents composants.

| Namespace | Contenu |
|-----------|---------|
| `default` | Microservices Whispr |
| `argocd` | ArgoCD |
| `istio-system` | Istio control plane |
| `cert-manager` | Cert-Manager |
| `vault` | HashiCorp Vault |
| `monitoring` | Prometheus, Grafana, Loki |

## Schéma

```
┌─────────────────────────────────────────┐
│             GKE Cluster                  │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ default  │  │ argocd   │  │ vault  │ │
│  │(services)│  │          │  │        │ │
│  └──────────┘  └──────────┘  └────────┘ │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │  istio-  │  │  cert-   │  │monitor-│ │
│  │  system  │  │  manager │  │  ing   │ │
│  └──────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────┘
```
