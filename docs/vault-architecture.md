# Architecture Vault

## Gestion des secrets

HashiCorp Vault est utilisé pour centraliser la gestion des secrets dans le cluster.

## Flux des secrets

```
┌───────────┐     ┌───────────────────┐     ┌──────────────┐
│  Vault    │────▶│ External Secrets  │────▶│  Kubernetes  │
│  Server   │     │   Operator (ESO)  │     │   Secrets    │
└───────────┘     └───────────────────┘     └──────┬───────┘
                                                    │
                                              ┌─────▼─────┐
                                              │   Pods    │
                                              │ (env vars)│
                                              └───────────┘
```
