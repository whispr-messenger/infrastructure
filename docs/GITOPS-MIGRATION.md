# Migration GitOps - Configurations Kubernetes dans les repos de microservices

## Vue d'ensemble

Cette migration déplace les configurations Kubernetes de chaque microservice depuis le repository `infrastructure` centralisé vers le repository propre de chaque microservice.

## Architecture cible

### Avant (structure centralisée)
```
infrastructure/
└── argocd/
    └── infrastructure/
        └── microservices/
            ├── messaging-service/
            │   └── messaging-service.yaml
            └── scheduling-service/
                └── scheduling-service.yaml
```

### Après (structure distribuée)
```
messaging-service/              # Repo du microservice
└── k8s/
    ├── base/                   # Manifestes de base (Kustomize)
    │   ├── kustomization.yaml
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   ├── secret.yaml
    │   ├── hpa.yaml
    │   ├── pdb.yaml
    │   ├── virtualservice.yaml
    │   └── destinationrule.yaml
    └── overlays/
        ├── development/        # Config dev
        │   └── kustomization.yaml
        ├── staging/            # Config staging
        │   └── kustomization.yaml
        └── production/         # Config production
            └── kustomization.yaml

infrastructure/                 # Repo infrastructure
└── argocd/
    └── applications/
        └── messaging-service.yaml  # Pointe vers messaging-service/k8s
```

## Avantages

1. **Autonomie des équipes** : Chaque équipe gère ses propres configurations K8s
2. **Versioning cohérent** : Les configs K8s suivent les versions du code applicatif
3. **CI/CD simplifié** : Déploiement automatique lors des releases
4. **Réduction de la complexité** : Repository infrastructure allégé
5. **Meilleure traçabilité** : Historique Git aligné avec le code

## Structure Kustomize recommandée

### Base (k8s/base/)

Contient les ressources communes à tous les environnements :

```yaml
# k8s/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: whispr-prod

resources:
  - namespace.yaml
  - serviceaccount.yaml
  - deployment.yaml
  - service.yaml
  - hpa.yaml
  - pdb.yaml
  - virtualservice.yaml
  - destinationrule.yaml

configMapGenerator:
  - name: messaging-service-config
    literals:
      - MIX_ENV=prod
      - PHX_SERVER=true
      - PORT=4000
      - GRPC_PORT=4001
      - LOG_LEVEL=info

secretGenerator:
  - name: messaging-service-secrets
    literals:
      - DATABASE_URL=postgresql://user:pass@host/db
      - REDIS_URL=redis://redis:6379/0
```

### Overlays par environnement

```yaml
# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: whispr-prod

resources:
  - ../../base

replicas:
  - name: messaging-service
    count: 2

images:
  - name: ghcr.io/whispr-messenger/messaging-service
    newTag: latest

configMapGenerator:
  - name: messaging-service-config
    behavior: merge
    literals:
      - PHX_HOST=whispr.io
      - POOL_SIZE=10

patches:
  - path: resources-patch.yaml
    target:
      kind: Deployment
      name: messaging-service
```

## Migration étape par étape

### Pour chaque microservice

#### 1. Créer la structure k8s dans le repo du microservice

```bash
cd messaging-service/

mkdir -p k8s/{base,overlays/{development,staging,production}}

# Copier les manifestes existants
cp ../infrastructure/argocd/infrastructure/microservices/messaging-service/messaging-service.yaml \
   k8s/base/all.yaml
```

#### 2. Découper le fichier monolithique en ressources individuelles

```bash
cd k8s/base/

# Extraire chaque ressource dans un fichier séparé
# Namespace
yq 'select(.kind == "Namespace")' all.yaml > namespace.yaml

# ServiceAccount
yq 'select(.kind == "ServiceAccount")' all.yaml > serviceaccount.yaml

# ConfigMap
yq 'select(.kind == "ConfigMap")' all.yaml > configmap.yaml

# Secret
yq 'select(.kind == "Secret")' all.yaml > secret.yaml

# Deployment
yq 'select(.kind == "Deployment")' all.yaml > deployment.yaml

# Service
yq 'select(.kind == "Service")' all.yaml > service.yaml

# HPA
yq 'select(.kind == "HorizontalPodAutoscaler")' all.yaml > hpa.yaml

# PDB
yq 'select(.kind == "PodDisruptionBudget")' all.yaml > pdb.yaml

# VirtualService
yq 'select(.kind == "VirtualService")' all.yaml > virtualservice.yaml

# DestinationRule
yq 'select(.kind == "DestinationRule")' all.yaml > destinationrule.yaml

# Supprimer le fichier temporaire
rm all.yaml
```

#### 3. Créer le fichier kustomization.yaml de base

```bash
cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: whispr-prod

resources:
  - namespace.yaml
  - serviceaccount.yaml
  - deployment.yaml
  - service.yaml
  - hpa.yaml
  - pdb.yaml
  - virtualservice.yaml
  - destinationrule.yaml

# Remplacer ConfigMap et Secret en dur par des generators
configMapGenerator:
  - name: messaging-service-config
    literals:
      - MIX_ENV=prod
      - PHX_SERVER=true
      - PHX_HOST=whispr.io
      - PORT=4000
      - GRPC_PORT=4001
      - LOG_LEVEL=info
      - POOL_SIZE=10

secretGenerator:
  - name: messaging-service-secrets
    literals:
      - DATABASE_URL=postgresql://whispr:CHANGE_ME@postgresql.whispr-prod.svc.cluster.local:5432/whispr_messaging
      - REDIS_URL=redis://redis-master.whispr-prod.svc.cluster.local:6379/0
      - SECRET_KEY_BASE=CHANGE_ME_GENERATE_WITH_mix_phx_gen_secret

commonLabels:
  app.kubernetes.io/name: messaging-service
  app.kubernetes.io/part-of: whispr
EOF

# Supprimer configmap.yaml et secret.yaml (maintenant gérés par generators)
rm configmap.yaml secret.yaml
```

#### 4. Créer les overlays pour chaque environnement

```bash
# Production
cat > ../overlays/production/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: whispr-prod

resources:
  - ../../base

replicas:
  - name: messaging-service
    count: 2

images:
  - name: ghcr.io/whispr-messenger/messaging-service
    newTag: latest

configMapGenerator:
  - name: messaging-service-config
    behavior: merge
    literals:
      - PHX_HOST=whispr.io
      - LOG_LEVEL=info
      - POOL_SIZE=10
EOF

# Staging
cat > ../overlays/staging/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: whispr-staging

resources:
  - ../../base

replicas:
  - name: messaging-service
    count: 1

images:
  - name: ghcr.io/whispr-messenger/messaging-service
    newTag: staging

configMapGenerator:
  - name: messaging-service-config
    behavior: merge
    literals:
      - PHX_HOST=staging.whispr.io
      - LOG_LEVEL=debug
      - POOL_SIZE=5
EOF

# Development
cat > ../overlays/development/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: whispr-dev

resources:
  - ../../base

replicas:
  - name: messaging-service
    count: 1

images:
  - name: ghcr.io/whispr-messenger/messaging-service
    newTag: dev

configMapGenerator:
  - name: messaging-service-config
    behavior: merge
    literals:
      - PHX_HOST=dev.whispr.io
      - LOG_LEVEL=debug
      - POOL_SIZE=2
EOF
```

#### 5. Tester la génération Kustomize

```bash
# Vérifier la sortie pour production
kustomize build k8s/overlays/production

# Vérifier pour staging
kustomize build k8s/overlays/staging

# Vérifier pour development
kustomize build k8s/overlays/development
```

#### 6. Mettre à jour le manifeste ArgoCD Application

Le fichier a déjà été mis à jour dans `infrastructure/argocd/applications/messaging-service.yaml` :

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: messaging-service
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/whispr-messenger/messaging-service
    targetRevision: main
    path: k8s/overlays/production
  # ... reste de la config
```

#### 7. Commit et push dans le repo du microservice

```bash
cd messaging-service/

git add k8s/
git commit -m "feat(k8s): add Kubernetes manifests with Kustomize structure"
git push origin main
```

#### 8. Synchroniser ArgoCD

```bash
# Dans le repo infrastructure
cd infrastructure/

git add argocd/applications/messaging-service.yaml
git commit -m "feat(argocd): point messaging-service to its own repository"
git push origin main

# Synchroniser ArgoCD
argocd app sync messaging-service
```

## Liste des microservices à migrer

- [x] messaging-service
- [x] scheduling-service
- [ ] auth-service (si existe)
- [ ] user-service (si existe)
- [ ] notification-service (si existe)

## Gestion des secrets

### Recommandation : External Secrets Operator

Au lieu de stocker les secrets en dur dans Git, utilisez External Secrets Operator :

```yaml
# k8s/base/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: messaging-service-secrets
  namespace: whispr-prod
spec:
  secretStoreRef:
    name: aws-secrets-manager  # ou vault, gcp, etc.
    kind: SecretStore
  target:
    name: messaging-service-secrets
    creationPolicy: Owner
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

## Validation

### Checklist par microservice

- [ ] Structure k8s créée dans le repo du microservice
- [ ] Manifestes découpés en ressources individuelles
- [ ] Kustomization.yaml configuré pour base et overlays
- [ ] Tests kustomize build réussis pour tous les environnements
- [ ] Manifeste ArgoCD Application mis à jour
- [ ] Synchronisation ArgoCD réussie
- [ ] Pods déployés et healthy
- [ ] Anciennes configurations supprimées du repo infrastructure

### Commandes de vérification

```bash
# Vérifier le statut de l'application
argocd app get messaging-service

# Vérifier les pods
kubectl get pods -n whispr-prod -l app=messaging-service

# Vérifier les logs
kubectl logs -n whispr-prod -l app=messaging-service --tail=50

# Comparer les manifestes générés avec les anciens
diff <(kubectl get deployment messaging-service -n whispr-prod -o yaml) \
     <(kustomize build messaging-service/k8s/overlays/production | yq 'select(.kind == "Deployment")')
```

## Nettoyage post-migration

Une fois tous les microservices migrés :

```bash
cd infrastructure/

# Supprimer les anciennes configurations
rm -rf argocd/infrastructure/microservices/

git add -A
git commit -m "chore: remove obsolete microservices configs after migration"
git push origin main
```

## Automatisation CI/CD

### Exemple GitHub Actions pour auto-déploiement

```yaml
# .github/workflows/deploy.yml dans le repo du microservice
name: Deploy to Kubernetes

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Update image tag in Kustomization
        run: |
          cd k8s/overlays/production
          kustomize edit set image \
            ghcr.io/whispr-messenger/messaging-service=ghcr.io/whispr-messenger/messaging-service:${{ github.sha }}

      - name: Commit and push
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add k8s/overlays/production/kustomization.yaml
          git commit -m "chore(k8s): update image tag to ${{ github.sha }}"
          git push
```

## Support et questions

Pour toute question sur la migration, contacter l'équipe Platform Engineering.
