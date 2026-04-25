# Network Policies

## Isolation réseau

Les namespaces sont isolés via des NetworkPolicies Kubernetes.

```
┌──────────────┐     ┌──────────────┐
│   default    │     │  monitoring  │
│ (services)   │     │ (prometheus) │
└──────┬───────┘     └──────┬───────┘
       │                     │
       │   Autorisé          │ Lecture seule
       │   (mTLS)            │ (scrape)
       ▼                     ▼
┌──────────────┐     ┌──────────────┐
│   vault      │     │  argocd      │
│ (secrets)    │     │  (gitops)    │
└──────────────┘     └──────────────┘
```

Seuls les services autorisés peuvent communiquer entre namespaces.
