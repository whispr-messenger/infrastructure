# Configuration Istio

## Service Mesh

Istio est utilisé comme service mesh pour gérer le trafic entre les microservices Whispr.

## Fonctionnalités activées

- **mTLS** : Chiffrement automatique du trafic inter-services
- **Traffic routing** : Routage basé sur les headers
- **Rate limiting** : Limitation du débit par service

## Architecture Istio

```
┌────────────────────────────────────┐
│           Istio Control Plane       │
│  ┌──────────┐                      │
│  │  istiod   │ (Pilot + Citadel)   │
│  └─────┬────┘                      │
│        │                           │
│  ┌─────▼────────────────────────┐  │
│  │       Data Plane              │  │
│  │  ┌────────┐    ┌────────┐    │  │
│  │  │ Envoy  │    │ Envoy  │    │  │
│  │  │ sidecar│    │ sidecar│    │  │
│  │  └───┬────┘    └───┬────┘    │  │
│  │      │             │         │  │
│  │  ┌───▼───┐    ┌────▼────┐   │  │
│  │  │ Auth  │    │Messaging│   │  │
│  │  │Service│    │ Service │   │  │
│  │  └───────┘    └─────────┘   │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```
