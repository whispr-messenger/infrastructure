# Terraform Configuration

Infrastructure as Code pour le déploiement de Whispr sur Google Kubernetes Engine.

## Structure

Les configurations Terraform sont organisées en workspaces Terraform Cloud numérotés, à exécuter dans l'ordre suivant :

### 1. `1-gcp-infrastructure`
**Dépendances:** Aucune

Crée l'infrastructure GCP de base :
- GKE Cluster
- VPC et sous-réseaux
- Service Account pour les nodes
- Configuration réseau (IP ranges pour pods et services)

**Outputs:**
- `cluster_name` - Nom du cluster GKE
- `cluster_endpoint` - Endpoint du cluster
- `cluster_ca_certificate` - Certificat CA du cluster
- `gcp_project_id` - ID du projet GCP
- `gke_zone` - Zone GKE

### 2. `2-kubernetes-bootstrap`
**Dépendances:** `1-gcp-infrastructure`

Initialise les namespaces et secrets Kubernetes :
- Namespaces: `argocd`, `postgresql`, `redis`, `sonarqube`, `whispr-prod`
- Secrets pour chaque service

**Remote State:**
- Utilise les outputs de `1-gcp-infrastructure` pour l'authentification au cluster

**Outputs:**
- `namespaces` - Map des namespaces créés
- `secrets` - Map des secrets créés

### 3. `3-argocd-installation`
**Dépendances:** `1-gcp-infrastructure`, `2-kubernetes-bootstrap`

Déploie ArgoCD via Helm :
- ArgoCD en mode High Availability
- Configuration avec Redis HA
- Autoscaling des composants
- Configuration initiale (domain, RBAC, repositories)

**Remote State:**
- Utilise les outputs de `1-gcp-infrastructure` pour l'authentification
- Utilise les outputs de `2-kubernetes-bootstrap` pour vérifier les namespaces

**Outputs:**
- `argocd_admin_password` - Mot de passe admin ArgoCD
- `argocd_domain` - Domain ArgoCD
- `argocd_namespace` - Namespace ArgoCD

## Ordre d'exécution

```bash
# 1. Infrastructure GCP
cd 1-gcp-infrastructure
terraform init
terraform plan
terraform apply

# 2. Bootstrap Kubernetes (après que GKE soit prêt)
cd ../2-kubernetes-bootstrap
terraform init
terraform plan
terraform apply

# 3. Installation ArgoCD (après les namespaces/secrets)
cd ../3-argocd-installation
terraform init
terraform plan
terraform apply
```

## Configuration Terraform Cloud

Chaque workspace est configuré pour utiliser Terraform Cloud :

```hcl
terraform {
  cloud {
    organization = "whispr-messenger"
    workspaces {
      name = "<workspace-name>"
    }
  }
}
```

### Chaînage des workspaces

Les workspaces utilisent le remote state pour accéder aux outputs des workspaces précédents :

```hcl
data "terraform_remote_state" "gcp_infra" {
  backend = "remote"
  config = {
    organization = "whispr-messenger"
    workspaces = {
      name = "1-gcp-infrastructure"
    }
  }
}
```

## Variables requises

### 1-gcp-infrastructure
```hcl
gcp_project_id   = "your-project-id"
gke_zone         = "europe-west1-b"
gke_cluster_name = "whispr-cluster"
```

### 2-kubernetes-bootstrap
Voir `terraform.tfvars.example` pour la liste complète des secrets.

### 3-argocd-installation
```hcl
argocd_namespace      = "argocd"
argocd_admin_password = "" # Auto-généré si vide
argocd_domain         = "argocd.whispr.epitech-msc2026.me"
```

## Modules

### `modules/google_kubernetes_engine`
Module réutilisable pour créer un cluster GKE avec :
- VPC dédié
- Configuration réseau optimisée
- Service Account avec permissions minimales
- Node pool avec autoscaling
- Workload Identity activé

## Post-déploiement

Après l'exécution des 3 workspaces :

1. Récupérer les credentials du cluster :
   ```bash
   gcloud container clusters get-credentials whispr-cluster --zone europe-west1-b
   ```

2. Vérifier ArgoCD :
   ```bash
   kubectl get pods -n argocd
   ```

3. Récupérer le mot de passe admin ArgoCD (si auto-généré) :
   ```bash
   terraform output -raw argocd_admin_password
   ```

4. Déployer l'App of Apps ArgoCD :
   ```bash
   kubectl apply -f argocd/root.yaml
   ```
