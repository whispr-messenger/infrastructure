# Topologie réseau du cluster

## Vue d'ensemble

Le cluster GKE Whispr utilise Istio comme service mesh pour gérer le trafic entre les microservices.

## Flux réseau entrant

```
Client (HTTPS)
     │
     ▼
┌─────────────┐
│ Cloud DNS   │
│ whispr.fr   │
└──────┬──────┘
       │
┌──────▼──────┐
│ GCP Load    │
│ Balancer    │
└──────┬──────┘
       │
┌──────▼──────────┐
│ Nginx Ingress   │
│ Controller      │
│ (TLS termination)│
└──────┬──────────┘
       │
┌──────▼──────┐
│ Istio       │
│ Gateway     │
└──────┬──────┘
       │
       ▼
  Microservices
```

## Communication inter-services

```
┌──────────┐    mTLS    ┌──────────┐
│   Auth   │◄──────────▶│   User   │
│  Service │            │  Service │
└────┬─────┘            └──────────┘
     │ mTLS
     │
┌────▼─────┐    mTLS    ┌──────────────┐
│Messaging │◄──────────▶│ Notification │
│ Service  │            │   Service    │
└──────────┘            └──────────────┘
```

Tout le trafic inter-services passe par les sidecars Envoy d'Istio avec du mTLS automatique.

## Ports exposés

| Service | Port REST | Port gRPC |
|---------|-----------|-----------|
| auth-service | 3000 | 50051 |
| messaging-service | 4000 | 50052 |
| user-service | 3000 | - |
| notification-service | 4000 | 50053 |
| scheduling-service | 3000 | 50051 |
| media-service | 3000 | - |
| moderation-service | 8000 | 50052 |
