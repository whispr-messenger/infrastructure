# Cert-Manager

## Rôle

Cert-Manager gère automatiquement les certificats TLS pour tous les services exposés.

## Fonctionnement

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Cert-Manager │────▶│ Let's Encrypt│────▶│  Certificat  │
│  (K8s)       │     │   (ACME)     │     │  TLS auto    │
└──────────────┘     └──────────────┘     └──────────────┘
```

## Domaines couverts

- `whispr.fr`
- `*.whispr.fr`
- `argocd.whispr.epitech.beer`
