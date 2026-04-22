# WHISPR-1069 — Backups automatiques

Deux `CronJob` tournent tous les jours contre le cluster preprod :

| Job | Namespace | Horaire (UTC) | Destination |
|-----|-----------|---------------|-------------|
| `postgres-backup` | `postgresql` | 02:00 | `minio/whispr-backups/postgres/YYYY-MM-DDTHH-MM-SSZ.sql.gz` |
| `minio-backup` | `minio` | 03:00 | `minio/whispr-backups/minio/whispr-media/` (mc mirror) |

## Pré-requis

Créer le bucket de destination et le secret `minio-backup-credentials`
dans les deux namespaces (`postgresql`, `minio`) :

```bash
# 1) Bucket de destination
mc mb minio/whispr-backups

# 2) Créer un utilisateur dédié avec accès readwrite sur whispr-backups
# (root MinIO conseillé uniquement pour le bootstrap)

# 3) Secret dans chaque namespace ciblé
kubectl -n postgresql create secret generic minio-backup-credentials \
  --from-literal=mc-host=https://<access>:<secret>@minio.minio.svc.cluster.local:9000
kubectl -n minio create secret generic minio-backup-credentials \
  --from-literal=mc-host=https://<access>:<secret>@minio.minio.svc.cluster.local:9000
```

## Validation

```bash
kubectl apply --dry-run=client -f postgres-backup-cronjob.yaml
kubectl apply --dry-run=client -f minio-backup-cronjob.yaml
kubectl -n postgresql create job --from=cronjob/postgres-backup manual-test
kubectl -n minio create job --from=cronjob/minio-backup manual-test
```

## Restauration

```bash
# Postgres — télécharger le dump, restaurer dans un cluster cible
mc cp minio/whispr-backups/postgres/<file>.sql.gz ./
gunzip <file>.sql.gz
psql -h postgresql.postgresql.svc.cluster.local -U postgres -f <file>.sql

# MinIO — re-mirror
mc mirror minio/whispr-backups/minio/whispr-media minio/whispr-media
```
