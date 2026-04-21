# Stratégie de backup

## PostgreSQL

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ PostgreSQL│────▶│ Snapshot │────▶│  GCS     │
│  (live)  │     │  GCP     │     │ (archive)│
└──────────┘     └──────────┘     └──────────┘
```

Fréquence : snapshot automatique toutes les 24h.

## Redis

Redis est utilisé comme cache, pas de backup nécessaire. Les données sont reconstituées au démarrage.

## Vault

Les données Vault sont persistées sur un PVC (Persistent Volume Claim). En cas de perte complète, réinitialiser avec les scripts dans `scripts/vault/`.
