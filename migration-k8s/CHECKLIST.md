# Checklist de migration GitOps

## Pré-migration

### Infrastructure repository
- [x] Manifestes ArgoCD Application mis à jour
- [x] Conflits Git résolus
- [x] Configurations K8s préparées dans `migration-k8s/`
- [x] Documentation créée
- [x] Anciennes configs supprimées

### Repositories des microservices
- [ ] Repository `messaging-service` cloné localement
- [ ] Repository `scheduling-service` cloné localement
- [ ] Branches de travail créées (ex: `feat/k8s-configs`)

## Pour messaging-service

### 1. Copie des configurations
- [ ] Dossier `k8s/` copié dans la racine du repo
- [ ] Structure vérifiée :
  ```
  messaging-service/
  └── k8s/
      ├── base/
      │   ├── namespace.yaml
      │   ├── serviceaccount.yaml
      │   ├── deployment.yaml
      │   ├── service.yaml
      │   ├── hpa.yaml
      │   ├── pdb.yaml
      │   ├── virtualservice.yaml
      │   ├── destinationrule.yaml
      │   └── kustomization.yaml
      └── overlays/
          ├── development/
          │   └── kustomization.yaml
          ├── staging/
          │   └── kustomization.yaml
          └── production/
              └── kustomization.yaml
  ```

### 2. Test Kustomize
- [ ] Production : `kubectl kustomize k8s/overlays/production`
- [ ] Staging : `kubectl kustomize k8s/overlays/staging`
- [ ] Development : `kubectl kustomize k8s/overlays/development`
- [ ] Aucune erreur de génération

### 3. Configuration des secrets

**Option A : External Secrets (recommandé)**
- [ ] External Secrets Operator installé dans le cluster
- [ ] SecretStore configuré (AWS/GCP/Vault)
- [ ] Fichier `k8s/base/externalsecret.yaml` créé
- [ ] `secretGenerator` supprimé du `kustomization.yaml`
- [ ] Secrets stockés dans le gestionnaire de secrets externe

**Option B : SealedSecrets**
- [ ] SealedSecrets installé dans le cluster
- [ ] Secrets scellés créés pour chaque environnement
- [ ] Fichiers `sealed-secret.yaml` ajoutés aux overlays
- [ ] `secretGenerator` supprimé du `kustomization.yaml`

**Option C : Valeurs par défaut (dev uniquement)**
- [ ] ⚠️ NE PAS utiliser en production
- [ ] Uniquement pour environnement de développement local

### 4. Git
- [ ] Fichiers ajoutés : `git add k8s/`
- [ ] Commit créé : `git commit -m "feat(k8s): add Kubernetes manifests with Kustomize structure"`
- [ ] Push effectué : `git push origin feat/k8s-configs`
- [ ] Pull request créée et mergée dans `main`

## Pour scheduling-service

### 1. Copie des configurations
- [ ] Dossier `k8s/` copié dans la racine du repo
- [ ] Structure vérifiée (similaire à messaging-service, sans `namespace.yaml`)

### 2. Test Kustomize
- [ ] Production : `kubectl kustomize k8s/overlays/production`
- [ ] Staging : `kubectl kustomize k8s/overlays/staging`
- [ ] Development : `kubectl kustomize k8s/overlays/development`
- [ ] Aucune erreur de génération

### 3. Configuration des secrets
- [ ] Même processus que messaging-service
- [ ] Secrets spécifiques à scheduling-service configurés

### 4. Git
- [ ] Fichiers ajoutés : `git add k8s/`
- [ ] Commit créé : `git commit -m "feat(k8s): add Kubernetes manifests with Kustomize structure"`
- [ ] Push effectué : `git push origin feat/k8s-configs`
- [ ] Pull request créée et mergée dans `main`

## Migration ArgoCD

### Infrastructure repository
- [ ] Changements dans `argocd/applications/` vérifiés
- [ ] Commit créé : `git commit -m "feat(argocd): migrate microservices to their own repositories"`
- [ ] Push effectué : `git push origin main`

### Synchronisation ArgoCD
- [ ] ArgoCD accessible : `argocd login`
- [ ] Application messaging-service synchronisée : `argocd app sync messaging-service`
- [ ] Application scheduling-service synchronisée : `argocd app sync scheduling-service`
- [ ] Aucune erreur de synchronisation

## Post-migration

### Validation messaging-service
- [ ] Pods démarrés : `kubectl get pods -n whispr-prod -l app=messaging-service`
- [ ] Tous les pods en état `Running`
- [ ] Logs sans erreur : `kubectl logs -n whispr-prod -l app=messaging-service --tail=50`
- [ ] Health checks OK
- [ ] Service accessible via Istio VirtualService
- [ ] Métriques Prometheus disponibles

### Validation scheduling-service
- [ ] Pods démarrés : `kubectl get pods -n whispr-prod -l app=scheduling-service`
- [ ] Tous les pods en état `Running`
- [ ] Logs sans erreur : `kubectl logs -n whispr-prod -l app=scheduling-service --tail=50`
- [ ] Health checks OK
- [ ] Service accessible via Istio VirtualService
- [ ] Communication avec messaging-service OK

### Validation ArgoCD
- [ ] Status messaging-service : `argocd app get messaging-service` → `Healthy & Synced`
- [ ] Status scheduling-service : `argocd app get scheduling-service` → `Healthy & Synced`
- [ ] Aucune ressource `OutOfSync`
- [ ] Aucune erreur dans l'UI ArgoCD

### Tests fonctionnels
- [ ] Endpoints HTTP accessibles
- [ ] Endpoints gRPC accessibles
- [ ] Base de données connectée
- [ ] Redis connecté
- [ ] Communication inter-services fonctionnelle
- [ ] Tests E2E passés

## Nettoyage

### Infrastructure repository
- [ ] Vérifier qu'aucune ancienne config ne reste
- [ ] Supprimer `migration-k8s/` (optionnel, après confirmation que tout fonctionne)
- [ ] Mettre à jour le README si nécessaire

### Documentation
- [ ] README des microservices mis à jour avec infos K8s
- [ ] Documentation d'architecture mise à jour
- [ ] Guide de déploiement mis à jour

## Rollback (si nécessaire)

Si un problème survient, vous pouvez rollback :

1. **Revert les changes ArgoCD dans infrastructure**
   ```bash
   git revert <commit-hash>
   git push origin main
   argocd app sync messaging-service
   ```

2. **Restaurer les anciennes configs** (si sauvegardées)
   ```bash
   git checkout <old-commit> -- argocd/infrastructure/microservices/
   git commit -m "chore: rollback to centralized configs"
   git push origin main
   ```

## Support

- Documentation complète : [docs/GITOPS-MIGRATION.md](../docs/GITOPS-MIGRATION.md)
- Statut : [MIGRATION-STATUS.md](../MIGRATION-STATUS.md)
- Issues : [GitHub Issues](https://github.com/whispr-messenger/infrastructure/issues)

---

**Date de début de migration** : _________________
**Date de fin de migration** : _________________
**Responsable** : _________________
