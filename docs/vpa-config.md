# Vertical Pod Autoscaler

## Rôle

Le VPA ajuste automatiquement les requests et limits CPU/mémoire des pods.

## Fonctionnement

```
VPA observe ──▶ Analyse usage ──▶ Recommandation ──▶ Update requests
  les pods        CPU/mémoire       nouvelle valeur     au prochain restart
```

## Mode

Le VPA est configuré en mode `Auto` : il applique les recommandations automatiquement.
