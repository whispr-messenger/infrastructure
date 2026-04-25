# Workflow de déploiement complet

## Schéma bout en bout

```
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Dev push│────▶│ GitHub   │────▶│ CI Build │────▶│ Push     │
│ sur main│     │ Actions  │     │ + Tests  │     │ Image    │
└─────────┘     └──────────┘     └──────────┘     │ GHCR     │
                                                   └────┬─────┘
                                                        │
┌─────────┐     ┌──────────┐     ┌──────────┐          │
│ Service │◀────│ ArgoCD   │◀────│ Update   │◀─────────┘
│ déployé │     │ sync     │     │ manifest │
│ sur GKE │     │          │     │ (tag)    │
└─────────┘     └──────────┘     └──────────┘
```

## Temps de déploiement

De push à déploiement effectif : ~5 minutes.
