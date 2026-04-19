# ArgoCD Sync Waves

## Ordre de déploiement

Les applications sont déployées dans un ordre précis via les sync waves ArgoCD :

```
Wave 1 ──▶ RBAC (permissions)
     │
Wave 2 ──▶ PostgreSQL, Redis, MinIO, ArgoCD
     │
Wave 3 ──▶ Cert-Manager (TLS)
     │
Wave 4 ──▶ Nginx Ingress
     │
Wave 10 ──▶ Microservices Whispr
```

## Pourquoi cet ordre ?

Les microservices dépendent des bases de données et du cache, qui eux-mêmes ont besoin des permissions RBAC. Les certificats TLS et l'ingress doivent être prêts avant d'exposer les services.

## Self-healing

ArgoCD compare en permanence l'état du cluster avec le contenu de ce repo git. Si quelqu'un modifie manuellement une ressource, ArgoCD la remet automatiquement en conformité.
