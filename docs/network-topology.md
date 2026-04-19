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
