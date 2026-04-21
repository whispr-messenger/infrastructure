# Alerting

## Règles d'alertes

| Alerte | Condition | Sévérité |
|--------|-----------|----------|
| HighErrorRate | Erreurs 5xx > 5% | Critical |
| HighLatency | P95 > 5s | Warning |
| PodCrashLoop | Restart > 5 en 10min | Critical |
| DiskPressure | Usage > 90% | Warning |
| QueueBacklog | Queue > 1000 jobs | Warning |

## Schéma

```
Prometheus ──▶ Alertmanager ──▶ Discord / Email
   (règles)      (routing)       (notification)
```
