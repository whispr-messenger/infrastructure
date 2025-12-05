# Quick Start - Migration GitOps

## TL;DR

```bash
# 1. Copier les configs dans les repos des microservices
cd /path/to/messaging-service
cp -r /path/to/infrastructure/migration-k8s/messaging-service/k8s .

cd /path/to/scheduling-service
cp -r /path/to/infrastructure/migration-k8s/scheduling-service/k8s .

# 2. Tester la génération
kubectl kustomize k8s/overlays/production

# 3. Configurer les secrets (IMPORTANT!)
# Voir CHECKLIST.md section "Configuration des secrets"

# 4. Commit et push
git add k8s/
git commit -m "feat(k8s): add Kubernetes manifests with Kustomize structure"
git push origin main

# 5. Dans le repo infrastructure, commit les changements ArgoCD
cd /path/to/infrastructure
git add argocd/applications/
git commit -m "feat(argocd): migrate microservices to their own repositories"
git push origin main

# 6. Synchroniser ArgoCD
argocd app sync messaging-service
argocd app sync scheduling-service

# 7. Vérifier
kubectl get pods -n whispr-prod
argocd app get messaging-service
argocd app get scheduling-service
```

## Structure créée

```
messaging-service/              # Dans le repo du microservice
└── k8s/
    ├── base/                   # Config de base
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── hpa.yaml
    │   ├── pdb.yaml
    │   ├── virtualservice.yaml
    │   ├── destinationrule.yaml
    │   └── kustomization.yaml
    └── overlays/
        ├── development/        # Namespace: whispr-dev
        ├── staging/            # Namespace: whispr-staging
        └── production/         # Namespace: whispr-prod
```

## Ce qui a changé

### Avant
```yaml
# infrastructure/argocd/applications/messaging-service.yaml
source:
  repoURL: https://github.com/whispr-messenger/infrastructure
  path: argocd/infrastructure/microservices/messaging-service
```

### Après
```yaml
# infrastructure/argocd/applications/messaging-service.yaml
source:
  repoURL: https://github.com/whispr-messenger/messaging-service
  path: k8s/overlays/production
```

## ⚠️ Points d'attention

1. **Secrets** : Ne pas commit de secrets en clair ! Utiliser External Secrets ou SealedSecrets
2. **Tests** : Toujours tester avec `kubectl kustomize` avant de commit
3. **Namespaces** : Vérifier que les namespaces existent dans le cluster
4. **ArgoCD** : Attendre que les configs soient dans les repos avant de sync ArgoCD

## Documentation complète

- [MIGRATION-STATUS.md](../MIGRATION-STATUS.md) - Statut et actions requises
- [CHECKLIST.md](CHECKLIST.md) - Checklist détaillée
- [docs/GITOPS-MIGRATION.md](../docs/GITOPS-MIGRATION.md) - Guide complet
- [README.md](README.md) - Instructions détaillées
