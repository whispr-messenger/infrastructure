# Helm Charts

## Charts utilisés

Le cluster utilise les Helm charts suivants pour les composants d'infrastructure :

| Chart | Version | Rôle |
|-------|---------|------|
| postgresql | - | Base de données partagée |
| redis | - | Cache et sessions |
| argocd | - | GitOps / CD |
| istio (base + istiod + gateway) | - | Service mesh |
| cert-manager | - | Certificats TLS |
| nginx-ingress | - | Ingress controller |
| vault | - | Secrets management |
| grafana | - | Dashboards monitoring |
| prometheus | - | Métriques |
| loki | - | Logs centralisés |
| promtail | - | Agent de collecte de logs |
| minio | - | Object storage |
| external-secrets | - | Sync Vault → K8s secrets |
| argo-rollouts | - | Déploiement canary / blue-green |
| atlas | - | Database schema management |
| vpa | - | Vertical Pod Autoscaler |

## Stack observabilité

```
┌───────────┐     ┌───────────┐     ┌──────────┐
│ Promtail  │────▶│   Loki    │────▶│ Grafana  │
│ (agent)   │     │  (logs)   │     │(dashboards│
└───────────┘     └───────────┘     └──────────┘
                                         ▲
┌───────────┐                            │
│Prometheus │────────────────────────────┘
│ (metrics) │
└───────────┘
```
