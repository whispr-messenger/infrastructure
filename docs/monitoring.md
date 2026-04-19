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
