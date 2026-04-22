# Argo Rollouts

## Stratégies de déploiement

Argo Rollouts permet des déploiements plus sûrs que le rolling update standard.

### Blue-Green

```
┌──────────┐     ┌──────────┐
│  Blue    │     │  Green   │
│ (actif)  │     │ (nouveau)│
└────┬─────┘     └────┬─────┘
     │                │
     └───── Switch ───┘
          (après tests)
```

### Canary

```
Trafic ──▶ 90% ancienne version
       ──▶ 10% nouvelle version
                │
          Métriques OK?
           oui  │  non
          ┌─────┼─────┐
          │           │
     Rollout 100%  Rollback
```
