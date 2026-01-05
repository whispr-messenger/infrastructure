# Infrastructure Whispr

Infrastructure pour le projet Whispr avec GitOps et Kubernetes.

## Quick Start

```bash
# Configuration initiale GCP
just setup-gcp-project

# Accès équipe plateforme
just setup-platform-access

# Voir toutes les commandes
just --list
```

## Structure

```
infrastructure/
├── argocd/                    # Configuration GitOps
│   ├── applications/          # Applications ArgoCD
│   ├── infrastructure/        # Infrastructure managée
│   └── microservices/         # Microservices deployments
├── scripts/                   # Scripts d'automation
├── secrets/                   # Secrets Kubernetes (templates)
│   ├── argocd/               # Secrets ArgoCD
│   ├── postgresql/           # Secrets PostgreSQL
│   ├── redis/                # Secrets Redis
│   ├── sonarqube/            # Secrets SonarQube
│   └── whispr-prod/          # Secrets microservices
├── terraform/                 # Infrastructure as Code
└── Justfile                   # Task automation
```

## Applications ArgoCD

| Application | Description | Sync Wave |
|-------------|-------------|-----------|
| `rbac` | Permissions et contrôles d'accès | 1 |
| `argocd` | ArgoCD self-management | 2 |
| `postgresql` | Base de données partagée | 2 |
| `redis` | Cache et sessions | 2 |
| `minio` | Stockage d'objets (media microservice) | 2 |
| `cert-manager` | Certificats TLS automatiques | 3 |
| `nginx-ingress` | Ingress controller | 4 |
| `sonarqube` | Qualité de code | 4 |
| `whispr-microservices` | Application principale | 10 |

### Workflow GitOps :

1. **Modification** : Push code dans git
2. **Auto-sync** : ArgoCD détecte les changements
3. **Déploiement** : Application dans l'ordre des sync waves
4. **Self-healing** : Correction automatique des dérives

## Accès équipe

**Admin :** `just setup-platform-access`  
**Membres :** Recevoir `platform-engineers-key.json` + suivre `scripts/platform-engineers/README-kubectl-setup-team.md`

## Infrastructure

**Cluster GKE :** `whispr-messenger` (europe-west1-b, projet magnetic-racer-476808-v4)

**Composants :**
- ArgoCD (GitOps)
- Istio (Service mesh)
- Cert-Manager (TLS)
- Nginx Ingress
- PostgreSQL
- Redis
- SonarQube

## Gestion des Secrets

Les secrets Kubernetes sont déployés automatiquement via GitHub Actions.

**Configuration :** Voir [secrets/SETUP.md](secrets/SETUP.md)

**Quick commands :**
```bash
# Générer des secrets forts
./secrets/generate-secrets.sh

# Vérifier les secrets déployés
./secrets/check-secrets.sh

# Déployer manuellement
gh workflow run deploy-secrets.yml
```

**Workflows disponibles :**
- `deploy-secrets.yml` : Déploie les secrets sur le cluster
- `validate-secrets.yml` : Valide les manifestes de secrets
