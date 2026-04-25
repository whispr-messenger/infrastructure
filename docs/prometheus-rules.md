# Règles Prometheus

## Exemples de requêtes PromQL

```promql
# Taux d'erreur 5xx par service (5 dernières minutes)
rate(http_requests_total{status=~"5.."}[5m])

# Latence P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Utilisation mémoire par pod
container_memory_usage_bytes / container_spec_memory_limit_bytes
```
