# Configurations Kubernetes pour migration GitOps

Ce dossier contient les configurations Kubernetes prêtes à être copiées dans les repositories respectifs des microservices.

## Structure

```
migration-k8s/
├── messaging-service/k8s/      # À copier dans le repo messaging-service
└── scheduling-service/k8s/     # À copier dans le repo scheduling-service
```

## Instructions de migration

### 1. Copier dans le repo du microservice

Pour chaque microservice, copiez le dossier `k8s/` dans la racine du repository correspondant :

```bash
# Exemple pour messaging-service
cd /path/to/messaging-service
cp -r /path/to/infrastructure/migration-k8s/messaging-service/k8s .

# Exemple pour scheduling-service
cd /path/to/scheduling-service
cp -r /path/to/infrastructure/migration-k8s/scheduling-service/k8s .
```

### 2. Vérifier la génération Kustomize

Avant de commit, vérifiez que Kustomize génère correctement les manifestes :

```bash
# Production
kustomize build k8s/overlays/production

# Staging
kustomize build k8s/overlays/staging

# Development
kustomize build k8s/overlays/development
```

### 3. Commit et push

```bash
git add k8s/
git commit -m "feat(k8s): add Kubernetes manifests with Kustomize structure"
git push origin main
```

### 4. Synchroniser ArgoCD

Les manifestes ArgoCD Application ont déjà été mis à jour dans ce repository pour pointer vers les nouveaux emplacements.

Après le push, ArgoCD détectera automatiquement les changements et synchronisera les applications.

Vous pouvez forcer la synchronisation :

```bash
argocd app sync messaging-service
argocd app sync scheduling-service
```

## Structure des fichiers

### Base (k8s/base/)

Contient les ressources communes à tous les environnements :
- `namespace.yaml` - Namespace Kubernetes (uniquement pour messaging-service)
- `serviceaccount.yaml` - ServiceAccount pour le pod
- `deployment.yaml` - Deployment de l'application
- `service.yaml` - Service ClusterIP
- `hpa.yaml` - HorizontalPodAutoscaler
- `pdb.yaml` - PodDisruptionBudget
- `virtualservice.yaml` - VirtualService Istio
- `destinationrule.yaml` - DestinationRule Istio
- `kustomization.yaml` - Configuration Kustomize base

### Overlays (k8s/overlays/)

Contient les personnalisations par environnement :

#### Production (`overlays/production/`)
- Namespace: `whispr-prod`
- Replicas: 2 (messaging), 2 (scheduling)
- Image tag: `latest`
- Resources: Production-ready

#### Staging (`overlays/staging/`)
- Namespace: `whispr-staging`
- Replicas: 1
- Image tag: `staging`
- Resources: Réduits

#### Development (`overlays/development/`)
- Namespace: `whispr-dev`
- Replicas: 1
- Image tag: `dev`
- Resources: Minimaux

## Gestion des secrets

⚠️ **Important** : Les secrets sont actuellement générés via `secretGenerator` dans le `kustomization.yaml` avec des valeurs par défaut.

### Pour la production

Vous devez remplacer les valeurs par défaut (`CHANGE_ME`) :

**Option 1 : SealedSecrets**
```bash
# Créer un secret
kubectl create secret generic messaging-service-secrets \
  --from-literal=DATABASE_URL="postgresql://..." \
  --from-literal=REDIS_URL="redis://..." \
  --from-literal=SECRET_KEY_BASE="..." \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > k8s/overlays/production/sealed-secret.yaml
```

**Option 2 : External Secrets Operator (recommandé)**

Remplacez le `secretGenerator` par un `ExternalSecret` :

```yaml
# k8s/base/externalsecret.yaml
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

## Validation

### Vérifier le déploiement

```bash
# Vérifier les pods
kubectl get pods -n whispr-prod -l app=messaging-service

# Vérifier les logs
kubectl logs -n whispr-prod -l app=messaging-service --tail=50

# Vérifier le statut ArgoCD
argocd app get messaging-service
```

### Comparer avec l'ancienne configuration

```bash
# Générer les manifestes actuels
kubectl get deployment messaging-service -n whispr-prod -o yaml > /tmp/old.yaml

# Générer les nouveaux manifestes
kustomize build k8s/overlays/production | yq 'select(.kind == "Deployment")' > /tmp/new.yaml

# Comparer
diff /tmp/old.yaml /tmp/new.yaml
```

## CI/CD automatique

Pour automatiser le déploiement lors des releases, ajoutez cette GitHub Action dans le repo du microservice :

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    tags: ['v*']

jobs:
  update-k8s:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Update image tag
        run: |
          cd k8s/overlays/production
          kustomize edit set image \
            ghcr.io/whispr-messenger/messaging-service=ghcr.io/whispr-messenger/messaging-service:${{ github.ref_name }}

      - name: Commit and push
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add k8s/overlays/production/kustomization.yaml
          git commit -m "chore(k8s): update image to ${{ github.ref_name }}"
          git push
```

## Support

Pour toute question, consultez la [documentation complète](../docs/GITOPS-MIGRATION.md).
