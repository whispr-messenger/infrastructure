# Pipeline CI/CD

## Vue d'ensemble

Le projet Whispr utilise GitHub Actions pour le CI et ArgoCD pour le CD (GitOps).

## Pipeline CI

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│   Push   │────▶│   Lint   │────▶│  Tests   │────▶│  Build   │
│  GitHub  │     │  Format  │     │  Unit/E2E│     │  Docker  │
└──────────┘     └──────────┘     └──────────┘     └──────┬───┘
                                                          │
                                                   ┌──────▼───┐
                                                   │  Push to  │
                                                   │   GHCR    │
                                                   └──────────┘
```
