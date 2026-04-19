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
