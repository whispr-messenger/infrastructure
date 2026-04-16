# Preprod Devzeyu (WHISPR-912)

Environnement preprod parallele a preprod-citadel, deploye sur le cluster
k3d `whispr-dev` de la station `devzeyu.com`, exposant les services sous
`https://whispr.devzeyu.com/*`.

## Schema

```
Externe
  https://whispr.devzeyu.com/
    └── host nginx (TLS, certbot) :443
        └── 127.0.0.1:8080 (k3d serverlb)
            └── Traefik (k3d built-in)
                ├── /auth/*         -> auth-service:3010
                ├── /user/*         -> user-service:3011
                ├── /media/*        -> media-service:3012
                ├── /messaging/*    -> messaging-service:4010
                ├── /notification/* -> notification-service:4011
                ├── /scheduling/*   -> scheduling-service:3013
                ├── /argocd/*       -> argocd-server (rootpath /argocd)
                └── /sonarqube/*    -> sonarqube (context /sonarqube)
```

## Composants deployes

| Namespace        | Composant                             | Source         |
|------------------|---------------------------------------|----------------|
| `argocd`         | ArgoCD (rootpath `/argocd`)           | helm chart     |
| `postgresql`     | PostgreSQL 15 (StatefulSet)           | `k8s/whispr/devzeyu/infra/postgres` |
| `redis`          | Redis 7                               | `k8s/whispr/devzeyu/infra/redis`    |
| `minio`          | MinIO                                 | `k8s/whispr/devzeyu/infra/minio`    |
| `sonarqube`      | SonarQube Community                   | helm (inline)  |
| `whispr-preprod` | 6 microservices + Traefik IngressRoute + middleware CORS | `k8s/whispr/preprod/*` (partage avec citadel) + `k8s/whispr/devzeyu/ingress` |

## GitOps

| Source                                        | Branche          | Consomme |
|-----------------------------------------------|------------------|----------|
| `argocd-preprod-devzeyu/`                     | `zeyu/preprod`   | Mes Applications ArgoCD |
| `k8s/whispr/devzeyu/`                         | `zeyu/preprod`   | Infra, ingress, overlays |
| `k8s/whispr/preprod/<service>/`               | `deploy/preprod` | Manifests services partages avec citadel |
| `k8s/whispr/preprod/infra/jwt-keys.yaml`      | `deploy/preprod` | Cle JWT partagee |

**Bumps d'images** : le bot GH Actions pousse les nouveaux tags
`sha-<x>` sur `deploy/preprod`. Les Applications devzeyu qui pointent
sur `deploy/preprod` detectent le changement et synchronisent
automatiquement. Aucune modification de `deploy/preprod` par nous.

## Bootstrap

Depuis cette machine (`pc`, user `pc`) :

```bash
# Optionnel : si les packages GHCR sont prives
export GHCR_USER=HouEpitech
export GHCR_TOKEN=ghp_xxx   # scope read:packages

cd /home/pc/whispr-preprod-work/infrastructure/scripts/preprod-devzeyu
./bootstrap.sh
```

Duree : 5-15 min (attente d'ArgoCD puis sync initiale).

## Secrets

Generes au premier lancement dans `/home/pc/.whispr-preprod/secrets.env`
(mode 0600). **Jamais commit**.

Contenu :
- `PG_PASSWORD`
- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`
- `ARGOCD_ADMIN_PASSWORD`
- `SONAR_ADMIN_PASSWORD`

Pour consulter :

```bash
cat ~/.whispr-preprod/secrets.env
```

Pour reinitialiser : supprimer le fichier et relancer bootstrap.

## Commandes utiles

```bash
# Etat global ArgoCD
kubectl -n argocd get application

# Redeclencher le root app (par exemple apres pull zeyu/preprod)
./bootstrap.sh --refresh-apps

# Logs d'un service
kubectl -n whispr-preprod logs -l app=auth-service --tail=100

# Rollout force d'un service (si image pull sans changement de tag)
kubectl -n whispr-preprod rollout restart deployment/auth-service

# Mot de passe admin ArgoCD (initial helm)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## Rollback

```bash
# Supprimer tous les deploiements devzeyu (ne touche pas citadel)
kubectl delete application whispr-preprod-devzeyu-root -n argocd --cascade=foreground

# Ou tout nettoyer
helm uninstall argocd -n argocd
kubectl delete ns argocd whispr-preprod postgresql redis minio sonarqube
```

## Garanties de non-impact

- Aucun write sur `deploy/preprod` ni `main`.
- Aucun fichier existant du repo modifie (seulement ajouts sous `argocd-preprod-devzeyu/`, `k8s/whispr/devzeyu/`, `scripts/preprod-devzeyu/`).
- Cluster k3d `whispr-dev` local - n'affecte pas le cluster citadel.
- vhost nginx : seul `whispr.devzeyu.com` recoit des en-tetes WebSocket ajoutes (pattern identique aux autres vhosts existants).

## Ticket

WHISPR-912
