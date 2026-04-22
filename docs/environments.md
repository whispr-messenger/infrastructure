# Environnements

## Vue d'ensemble

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Local    │────▶│   Preprod   │────▶│ Production  │
│   (k3d)    │     │   (GKE)     │     │   (GKE)     │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Comparaison

| | Local | Preprod | Production |
|-|-------|---------|------------|
| Cluster | k3d (Docker) | GKE | GKE |
| Namespace | default | default | default |
| Replicas | 1 | 1 | 2-3 |
| TLS | Non | Oui | Oui |
| Vault | Non | Oui | Oui |
| Monitoring | Non | Partiel | Complet |
