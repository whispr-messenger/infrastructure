# Kargo

## Rôle

Kargo est un outil de promotion d'images entre environnements.

## Flux

```
Build image ──▶ GHCR ──▶ Kargo ──▶ Promotion preprod ──▶ prod
```

Il automatise la mise à jour des tags d'images dans les manifests K8s.
