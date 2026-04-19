# Preprod vs Production

## Différences

| Aspect | Preprod | Production |
|--------|---------|------------|
| Branche source | deploy/preprod | main |
| Manifests K8s | k8s/whispr/preprod/ | k8s/whispr/prod/ |
| Replicas | 1 | 2-3 |
| Resources | Requests réduits | Requests production |
| Auto-sync ArgoCD | Oui | Oui |

## Flux de promotion

```
Feature branch ──▶ PR ──▶ main ──▶ deploy/preprod ──▶ prod
                                        │
                                   Tests E2E
                                   Validation
```
