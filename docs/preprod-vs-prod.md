# Preprod vs Production

## Différences

| Aspect | Preprod | Production |
|--------|---------|------------|
| Branche source | deploy/preprod | main |
| Manifests K8s | k8s/whispr/preprod/ | k8s/whispr/prod/ |
| Replicas | 1 | 2-3 |
| Resources | Requests réduits | Requests production |
| Auto-sync ArgoCD | Oui | Oui |
