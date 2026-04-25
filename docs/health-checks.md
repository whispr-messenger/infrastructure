# Health Checks

## Probes Kubernetes

Chaque microservice expose des probes pour Kubernetes :

```
┌─────────────┐     ┌──────────────┐
│  kubelet    │────▶│  /health     │ (liveness)
│             │────▶│  /ready      │ (readiness)
└─────────────┘     └──────────────┘
```

| Probe | Rôle | Conséquence si fail |
|-------|------|---------------------|
| liveness | Le pod est vivant ? | Restart du pod |
| readiness | Le pod peut recevoir du trafic ? | Retiré du service |
