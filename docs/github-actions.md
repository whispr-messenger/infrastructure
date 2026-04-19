# GitHub Actions

## Workflows CI

Chaque microservice a ses propres workflows CI dans son repo `.github/workflows/`.

## Actions Runner

Le cluster utilise un ARC (Actions Runner Controller) autohébergé pour exécuter les jobs CI directement dans le cluster GKE.

```
GitHub Event ──▶ ARC Controller ──▶ Runner Pod ──▶ Job execution
                                        │
                                   Cleanup auto
                                   après le job
```
