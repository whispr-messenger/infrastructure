# mTLS Istio

## Principe

```
┌─────────┐          ┌─────────┐
│ Service │  mTLS    │ Service │
│    A    │◄────────▶│    B    │
│         │          │         │
│ ┌─────┐ │          │ ┌─────┐ │
│ │Envoy│ │          │ │Envoy│ │
│ └─────┘ │          │ └─────┘ │
└─────────┘          └─────────┘
```

Chaque pod a un sidecar Envoy qui chiffre automatiquement le trafic sortant et déchiffre le trafic entrant.

## Mode

Le mode `STRICT` est activé : tout le trafic dans le mesh doit être mTLS.
