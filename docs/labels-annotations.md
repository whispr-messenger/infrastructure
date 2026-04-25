# Labels et Annotations

## Labels standards

| Label | Valeur | Usage |
|-------|--------|-------|
| app | nom-du-service | Sélection pods |
| version | v1.x.x | Versioning |
| environment | prod/preprod | Environnement |
| managed-by | argocd | Outil de gestion |

## Sélecteurs

```yaml
selector:
  matchLabels:
    app: auth-service
```
