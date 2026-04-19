# Infrastructure Whispr

Infrastructure pour le projet Whispr avec GitOps et Kubernetes.

## Table des matières

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Structure](#structure)
- [Applications ArgoCD](#applications-argocd)
- [Infrastructure](#infrastructure)
- [Gestion des Secrets](#gestion-des-secrets)

## Quick Start

```bash
# Configuration initiale GCP
just setup-gcp-project

# Accès équipe plateforme
just setup-platform-access

# Voir toutes les commandes
just --list
```

## Architecture globale

```
┌─────────────────────────────────────────────────┐
│                   Internet                       │
└────────────────────┬────────────────────────────┘
                     │
              ┌──────▼──────┐
              │ Nginx Ingress│
              │  + TLS       │
              └──────┬──────┘
                     │
              ┌──────▼──────┐
              │  Istio Mesh  │
              │   (mTLS)     │
              └──────┬──────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
┌────▼────┐   ┌──────▼────┐   ┌─────▼─────┐
│  Auth   │   │ Messaging │   │   User    │
│ Service │   │  Service  │   │  Service  │
└────┬────┘   └─────┬─────┘   └─────┬─────┘
     │              │               │
     └──────────────┼───────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
   ┌────▼───┐  ┌────▼───┐  ┌───▼────┐
   │Postgres│  │ Redis  │  │ Vault  │
   └────────┘  └────────┘  └────────┘
```

### Pipeline GitOps

```
Developer ──▶ Git Push ──▶ GitHub ──▶ ArgoCD ──▶ GKE Cluster
                              │
                              ▼
                        GitHub Actions
                         (CI / Build)
```

## Structure

```
infrastructure/
├── argocd/                    # Configuration GitOps
│   ├── applications/          # Applications ArgoCD
│   ├── infrastructure/        # Infrastructure managée
│   └── microservices/         # Microservices deployments
├── docker/                    # Configs Docker (vault-config-job)
├── docs/                      # Documentation technique
├── helm/                      # Helm charts (istio, vault, grafana...)
├── k3d/                       # Config cluster local k3d
├── k8s/                       # Manifests Kubernetes
│   ├── whispr/prod/           # Manifests production
│   ├── whispr/preprod/        # Manifests preprod
│   ├── istio/                 # Config Istio
│   └── vault-secrets-operator/# ESO config
├── scripts/                   # Scripts d'automation
├── terraform/                 # Infrastructure as Code (GKE)
└── Justfile                   # Task automation
```

## Documentation détaillée

- [Topologie réseau](docs/network-topology.md)
- [Pipeline CI/CD](docs/ci-cd-pipeline.md)
- [Architecture Vault](docs/vault-architecture.md)
- [Helm Charts](docs/helm-charts.md)
- [Configuration Istio](docs/istio-config.md)
- [Terraform / GKE](docs/terraform.md)
- [Nginx Ingress](docs/nginx-ingress.md)
- [Redis](docs/redis-config.md)
- [PostgreSQL](docs/postgresql-config.md)
- [MinIO](docs/minio-storage.md)
- [Monitoring](docs/monitoring.md)
- [Scaling](docs/scaling.md)
- [ArgoCD Sync Waves](docs/argocd-sync-waves.md)
- [Cert-Manager](docs/cert-manager.md)
- [K8s Namespaces](docs/k8s-namespaces.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Dev local avec k3d](docs/local-dev-k8s.md)
- [Sécurité](SECURITY.md)
- [Contribuer](CONTRIBUTING.md)

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

**Cluster GKE :** `whispr-messenger` (europe-west1, projet tranquil-harbor-480911-k9)  
**Domaine :** whispr.fr ([Configuration DNS](DNS-CONFIGURATION.md))

**Composants :**
- ArgoCD (GitOps)
- Istio (Service mesh)
- Cert-Manager (TLS)
- Nginx Ingress
- PostgreSQL
- Redis
- **HashiCorp Vault** (Secrets management)
- **External Secrets Operator** (Kubernetes secrets sync)

## Gestion des Secrets

Les secrets sont gérés automatiquement via **HashiCorp Vault** et **External Secrets Operator**.

**Guide complet** : [scripts/vault/README-vault-setup.md](scripts/vault/README-vault-setup.md)

**Quick start** :
```bash
# Initialiser Vault (première fois uniquement)
cd scripts/vault
./init-vault.sh

# Peupler les secrets
./populate-secrets.sh

# Déployer le SecretStore
kubectl apply -f k8s/vault/vault-secret-store.yaml
```
