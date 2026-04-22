# Mises à jour du cluster

## GKE

Les mises à jour de version GKE sont gérées par Google (auto-upgrade activé).

## Helm charts

Pour mettre à jour un chart :

```bash
cd helm/<chart-name>
# Modifier values.yaml
git add . && git commit -m "update <chart> values"
git push
# ArgoCD sync automatique
```
