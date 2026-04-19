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

## Secrets par service

| Service | Secrets gérés |
|---------|---------------|
| auth-service | JWT keys, SMS API key, DB credentials |
| messaging-service | DB credentials, Redis password |
| user-service | DB credentials, Redis password |
| notification-service | FCM key, APNS cert, DB credentials |
| media-service | GCS credentials, encryption key, DB credentials |
| scheduling-service | DB credentials, Redis password |
