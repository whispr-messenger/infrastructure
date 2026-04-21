# Disaster Recovery

## Sauvegardes

### PostgreSQL

Les données PostgreSQL sont sauvegardées via les snapshots GCP automatiques.

### Vault

Les données Vault sont stockées sur un backend persistant. En cas de perte, réinitialiser avec `scripts/vault/init-vault.sh`.
