# Ports des services K8s

## Services ClusterIP

```
┌──────────────────────────────────────────────┐
│              Cluster K8s                      │
│                                               │
│  auth-service:3000          user-service:3000  │
│  messaging-service:4000     media-service:3000 │
│  notification-service:4000  scheduling:3000    │
│  moderation-service:8000                       │
│                                               │
│  PostgreSQL:5432  Redis:6379  Vault:8200       │
└──────────────────────────────────────────────┘
```

Tous les services sont en ClusterIP (non exposés directement). L'accès externe passe par Nginx Ingress.
