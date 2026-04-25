# Loki - Centralisation des logs

## Architecture

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│   Pod    │────▶│ Promtail │────▶│   Loki   │
│  (logs)  │     │ (agent)  │     │ (stockage)│
└──────────┘     └──────────┘     └────┬─────┘
                                       │
                                 ┌─────▼─────┐
                                 │  Grafana   │
                                 │ (requêtes) │
                                 └───────────┘
```

## Requêtes LogQL

Les logs sont consultables dans Grafana via LogQL.

Exemple : `{namespace="default", app="auth-service"} |= "error"`
