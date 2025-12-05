# Statut de la migration GitOps

## ✅ Modifications complétées

### 1. Manifestes ArgoCD Application mis à jour

Les applications ArgoCD pointent maintenant vers les repositories des microservices :

- **messaging-service** : [infrastructure/argocd/applications/messaging-service.yaml](argocd/applications/messaging-service.yaml)
  - `repoURL`: `https://github.com/whispr-messenger/messaging-service`
  - `path`: `k8s/overlays/production`

- **scheduling-service** : [infrastructure/argocd/applications/scheduling-service.yaml](argocd/applications/scheduling-service.yaml)
  - `repoURL`: `https://github.com/whispr-messenger/scheduling-service`
  - `path`: `k8s/overlays/production`

### 2. Configurations Kubernetes préparées

Les configurations Kubernetes avec Kustomize sont prêtes dans [migration-k8s/](migration-k8s/) :

```
migration-k8s/
├── messaging-service/k8s/
│   ├── base/                    # Ressources de base
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   ├── pdb.yaml
│   │   ├── virtualservice.yaml
│   │   ├── destinationrule.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── development/         # Config dev
│       ├── staging/             # Config staging
│       └── production/          # Config production
└── scheduling-service/k8s/
    └── (même structure)
```

### 3. Nettoyage effectué

- ✅ Suppression de [infrastructure/argocd/infrastructure/microservices/](argocd/infrastructure/microservices/)
- ✅ Résolution des conflits Git dans les manifestes ArgoCD

### 4. Documentation créée

- ✅ [docs/GITOPS-MIGRATION.md](docs/GITOPS-MIGRATION.md) - Guide complet de migration
- ✅ [migration-k8s/README.md](migration-k8s/README.md) - Instructions d'utilisation des configs
- ✅ [migration-k8s/test-kustomize.sh](migration-k8s/test-kustomize.sh) - Script de test

## 📋 Actions requises

### Pour chaque microservice

#### 1. Copier les configurations dans le repo du microservice

```bash
# messaging-service
cd /path/to/messaging-service
cp -r /path/to/infrastructure/migration-k8s/messaging-service/k8s .

# scheduling-service
cd /path/to/scheduling-service
cp -r /path/to/infrastructure/migration-k8s/scheduling-service/k8s .
```

#### 2. Tester la génération Kustomize

```bash
# Vérifier que tous les manifestes se génèrent correctement
kubectl kustomize k8s/overlays/production
kubectl kustomize k8s/overlays/staging
kubectl kustomize k8s/overlays/development
```

#### 3. Mettre à jour les secrets en production

⚠️ **Important** : Les secrets contiennent actuellement des valeurs par défaut `CHANGE_ME`.

**Option recommandée** : External Secrets Operator

Créez un fichier `k8s/base/externalsecret.yaml` :

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: messaging-service-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: messaging-service-secrets
  data:
    - secretKey: DATABASE_URL
      remoteRef:
        key: whispr/prod/messaging/database-url
    - secretKey: REDIS_URL
      remoteRef:
        key: whispr/prod/messaging/redis-url
    - secretKey: SECRET_KEY_BASE
      remoteRef:
        key: whispr/prod/messaging/secret-key-base
```

Et supprimez le `secretGenerator` du `kustomization.yaml`.

#### 4. Commit et push

```bash
git add k8s/
git commit -m "feat(k8s): add Kubernetes manifests with Kustomize structure"
git push origin main
```

#### 5. Synchroniser ArgoCD

```bash
# Dans le repo infrastructure
git add argocd/applications/
git commit -m "feat(argocd): migrate microservices to their own repositories"
git push origin main

# Synchroniser ArgoCD
argocd app sync messaging-service
argocd app sync scheduling-service
```

#### 6. Valider le déploiement

```bash
# Vérifier les pods
kubectl get pods -n whispr-prod -l app=messaging-service
kubectl get pods -n whispr-prod -l app=scheduling-service

# Vérifier les logs
kubectl logs -n whispr-prod -l app=messaging-service --tail=50
kubectl logs -n whispr-prod -l app=scheduling-service --tail=50

# Vérifier ArgoCD
argocd app get messaging-service
argocd app get scheduling-service
```

## 🧪 Test de génération

Un test a été effectué avec succès :

```bash
kubectl kustomize migration-k8s/messaging-service/k8s/overlays/production
# ✅ Génération réussie
```

Les manifestes générés incluent :
- Namespace (whispr-prod)
- ServiceAccount
- ConfigMap (avec hash généré automatiquement)
- Secret (encodé en base64)
- Service
- Deployment (2 replicas)
- HorizontalPodAutoscaler
- PodDisruptionBudget
- VirtualService (Istio)
- DestinationRule (Istio)

## 🎯 Avantages de la nouvelle structure

1. **Autonomie** : Chaque équipe gère ses configs K8s
2. **Versioning cohérent** : Configs alignées avec le code
3. **CI/CD simplifié** : Déploiement automatique possible
4. **Traçabilité** : Historique Git clair
5. **Multi-environnement** : Gestion propre via overlays Kustomize

## 📚 Ressources

- [Documentation Kustomize](https://kustomize.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Guide de migration complet](docs/GITOPS-MIGRATION.md)

## ❓ Support

Pour toute question ou problème durant la migration, créer une issue ou contacter l'équipe Platform Engineering.

---

**Dernière mise à jour** : 5 décembre 2024
