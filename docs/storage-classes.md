# Storage Classes

## PersistentVolumes

| Service | Type | Taille | AccessMode |
|---------|------|--------|------------|
| PostgreSQL | SSD | 10Gi | ReadWriteOnce |
| Redis | SSD | 5Gi | ReadWriteOnce |
| Vault | SSD | 10Gi | ReadWriteOnce |
| MinIO | Standard | 50Gi | ReadWriteOnce |
| Prometheus | Standard | 20Gi | ReadWriteOnce |

## Schéma

```
Pod ──▶ PVC ──▶ PV ──▶ GCE Persistent Disk
```
