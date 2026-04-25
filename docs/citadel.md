# Citadel

## Configuration ArgoCD multi-environnement

Le dossier `argocd-preprod-citadel/` et `argocd-prod-citadel/` contiennent les overrides ArgoCD spécifiques à chaque environnement.

## Schéma

```
argocd/
├── applications/          # Apps communes
├── infrastructure/        # Infra commune
└── microservices/         # Services communs

argocd-preprod-citadel/    # Overrides preprod
argocd-prod-citadel/       # Overrides prod
```

Les overrides Citadel permettent de personnaliser les valeurs Helm par environnement sans dupliquer les manifests.
