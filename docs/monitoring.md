# Monitoring

## Stack

La stack de monitoring est composée de Prometheus, Grafana, Loki et Promtail.

## Dashboards Grafana

Les dashboards personnalisés sont stockés dans `helm/grafana/dashboards/`.

## Alertes

Les alertes sont configurées dans Prometheus et envoyées via les channels appropriés.

## Métriques collectées

```
Microservices ──▶ Prometheus ──▶ Grafana
     │                              │
     │          ┌───────────────────┘
     │          │
     ▼          ▼
  Promtail ──▶ Loki (logs)
```

## Accès

- Grafana : accessible via Nginx Ingress
- Prometheus : interne au cluster uniquement

## Dashboards disponibles

Les dashboards sont stockés dans `helm/grafana/dashboards/`.

| Dashboard | Métriques |
|-----------|-----------|
| API Latency | P50, P95, P99 par service |
| Error Rate | Taux d'erreur 4xx/5xx |
| Pod Resources | CPU et mémoire par pod |
| Redis | Connexions, hit rate, mémoire |
| PostgreSQL | Connexions actives, queries/s |
