# Cycle de vie d'un pod

## États

```
Pending ──▶ Running ──▶ Succeeded
                │
                ▼
             Failed ──▶ CrashLoopBackOff
                              │
                        Restart (backoff)
```

## Probes

```
kubelet
  │
  ├── startupProbe ──▶ Le container a démarré?
  ├── livenessProbe ──▶ Le container est vivant?
  └── readinessProbe ──▶ Le container peut recevoir du trafic?
```
