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

## Composants installés

| Composant | Chart Helm | Rôle |
|-----------|-----------|------|
| istio-base | helm/istio/base | CRDs Istio |
| istiod | helm/istio/istiod | Control plane |
| istio-gateway | helm/istio/gateway | Ingress gateway |
