# Disaster Recovery

## Sauvegardes

### PostgreSQL

Les données PostgreSQL sont sauvegardées via les snapshots GCP automatiques.

### Vault

Les données Vault sont stockées sur un backend persistant. En cas de perte, réinitialiser avec `scripts/vault/init-vault.sh`.

## Procédure de recovery

```
1. Recréer le cluster GKE (Terraform)
2. Restaurer les snapshots PostgreSQL
3. Réinitialiser Vault
4. ArgoCD re-sync automatique des services
```
