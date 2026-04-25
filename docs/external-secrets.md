# External Secrets Operator

## Rôle

ESO synchronise les secrets de Vault vers des Kubernetes Secrets.

## Fonctionnement

```
Vault ──▶ SecretStore ──▶ ExternalSecret ──▶ K8s Secret ──▶ Pod
```

Les ExternalSecrets sont définis dans `k8s/vault-secrets-operator/`.
