# [WHISPR-198] Provision Grafana : Prometheus datasource pour tests locaux

Ajoute un ConfigMap pour provisionner automatiquement Prometheus comme datasource dans Grafana (environnements de test locaux).

## Ce qui a été fait
- Ajout d'un ConfigMap de provisioning : `argocd/k8s/observability/grafana-datasource-provisioning.yaml` qui contient `prometheus.yaml`.
- Montage du ConfigMap dans le Deployment Grafana pour que la datasource soit créée au démarrage.
- Ajout de `securityContext.fsGroup: 472` dans `argocd/helm/grafana/values.yaml` pour régler proprement les permissions du PV (remplace le workaround d'init-container utilisé en local).
- Redémarrage des pods Grafana et vérification : le fichier `prometheus.yaml` est présent dans le pod et Grafana a provisionné la datasource.

## Checklist
- [x] ConfigMap de provisioning ajouté (`argocd/k8s/observability/grafana-datasource-provisioning.yaml`)
- [x] `fsGroup` ajouté dans `argocd/helm/grafana/values.yaml`
- [x] Pods Grafana redémarrés et datasource provisionnée automatiquement

## Notes
Le patch de l'init-container appliqué précédemment sur le cluster est un workaround local ; la configuration `fsGroup` dans les valeurs Helm doit permettre de s'en passer en local et en production. En production, préférez corriger les permissions du PV ou utiliser `securityContext` plutôt que d'ignorer les erreurs de `chown`.

## Commande recommandée pour créer la PR (si tu as `gh` installé)
```bash
gh pr create --base main --head setup-grafana-helm-chart \
  --title "[WHISPR-198] Provision Grafana : Prometheus datasource pour tests locaux" \
  --body "$(cat .github/PR_WHISPR-198.md)"
```

---

Tu peux maintenant copier-coller le contenu de ce fichier dans l'UI GitHub pour ouvrir la PR, ou exécuter la commande si `gh` est installé et configuré.
