# HashiCorp Vault Setup Guide

This guide explains how to initialize, configure, and use HashiCorp Vault for automated secrets management in the Whispr infrastructure.

## Overview

HashiCorp Vault is deployed in High Availability (HA) mode with Raft storage backend. External Secrets Operator is used to automatically sync secrets from Vault to Kubernetes Secrets.

## Architecture

```
┌─────────────────────┐
│  Vault (HA Mode)    │
│  - 3 replicas       │
│  - Raft storage     │
│  - Kubernetes auth  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ External Secrets    │
│ Operator            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Kubernetes Secrets  │
│ (Auto-generated)    │
└─────────────────────┘
```

## Prerequisites

- Vault and External Secrets Operator deployed via ArgoCD
- `kubectl` configured to access the cluster
- `jq` installed for JSON parsing

## Initial Setup

### Step 1: Deploy Vault and External Secrets

The following applications should be deployed via ArgoCD:
- `vault` (sync wave 2)
- `external-secrets` (sync wave 3)

Verify deployment:
```bash
# Check Vault pods
kubectl get pods -n vault

# Check External Secrets Operator
kubectl get pods -n external-secrets-system
```

### Step 2: Initialize Vault

Run the initialization script:

```bash
cd scripts/vault
chmod +x init-vault.sh
./init-vault.sh
```

**CRITICAL:** The script will output 5 unseal keys and a root token. **Save these securely immediately!**

Recommended storage options:
- Google Secret Manager
- 1Password / LastPass
- Encrypted file in a secure location

**Never commit these keys to Git!**

### Step 3: Populate Secrets

After initialization, populate Vault with secrets:

```bash
chmod +x populate-secrets.sh
./populate-secrets.sh
```

This creates secrets for:
- PostgreSQL (password, username, database)
- Redis (password)
- MinIO (root user, root password)
- Messaging Service (DATABASE_URL, REDIS_URL, SECRET_KEY_BASE)
- Scheduling Service (DATABASE_URL, REDIS_URL)
- Auth Service (DATABASE_URL, REDIS_URL, SECRET_KEY_BASE, JWT_SECRET)

### Step 4: Deploy ClusterSecretStore

Apply the ClusterSecretStore to connect External Secrets to Vault:

```bash
kubectl apply -f argocd/k8s/vault/vault-secret-store.yaml
```

Verify:
```bash
kubectl get clustersecretstore vault-backend
```

### Step 5: Deploy Services with ExternalSecrets

The microservices (messaging-service, scheduling-service) now use ExternalSecrets instead of hardcoded Secrets. ArgoCD will automatically create the Kubernetes Secrets from Vault.

Verify ExternalSecrets:
```bash
kubectl get externalsecrets -n whispr-prod
kubectl describe externalsecret messaging-service-secrets -n whispr-prod
```

## Daily Operations

### Unsealing Vault

If Vault pods restart, they need to be unsealed manually:

```bash
# Get Vault pod name
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

# Unseal with 3 of the 5 keys
kubectl exec -n vault $VAULT_POD -- vault operator unseal <UNSEAL_KEY_1>
kubectl exec -n vault $VAULT_POD -- vault operator unseal <UNSEAL_KEY_2>
kubectl exec -n vault $VAULT_POD -- vault operator unseal <UNSEAL_KEY_3>

# Repeat for all Vault pods
```

### Adding New Secrets

1. Login to Vault:
```bash
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n vault $VAULT_POD -- vault login <ROOT_TOKEN>
```

2. Add the secret:
```bash
kubectl exec -n vault $VAULT_POD -- vault kv put secret/my-service \
    key1="value1" \
    key2="value2"
```

3. Create an ExternalSecret manifest:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-service-secrets
  namespace: whispr-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: my-service-secrets
    creationPolicy: Owner
  data:
    - secretKey: KEY1
      remoteRef:
        key: secret/my-service
        property: key1
    - secretKey: KEY2
      remoteRef:
        key: secret/my-service
        property: key2
```

4. Apply the manifest and verify:
```bash
kubectl apply -f my-externalsecret.yaml
kubectl get secret my-service-secrets -n whispr-prod
```

### Rotating Secrets

1. Update the secret in Vault:
```bash
kubectl exec -n vault $VAULT_POD -- vault kv put secret/my-service \
    key1="new-value1"
```

2. External Secrets Operator will automatically sync the new value within the refresh interval (default: 1 hour)

3. To force immediate sync:
```bash
kubectl annotate externalsecret my-service-secrets -n whispr-prod \
    force-sync=$(date +%s) --overwrite
```

4. Restart the pods to use the new secret:
```bash
kubectl rollout restart deployment/my-service -n whispr-prod
```

### Viewing Secrets

To view a secret in Vault:
```bash
kubectl exec -n vault $VAULT_POD -- vault kv get secret/my-service
```

To view the generated Kubernetes secret:
```bash
kubectl get secret my-service-secrets -n whispr-prod -o yaml
```

## Troubleshooting

### ExternalSecret not syncing

Check the ExternalSecret status:
```bash
kubectl describe externalsecret my-service-secrets -n whispr-prod
```

Common issues:
- Vault is sealed (unseal it)
- Secret doesn't exist in Vault (create it)
- Wrong path or property name in ExternalSecret
- ClusterSecretStore not configured correctly

### Vault pods not starting

Check pod logs:
```bash
kubectl logs -n vault vault-0
```

Common issues:
- PersistentVolume not available
- Insufficient resources
- Configuration error in values.yaml

### Kubernetes auth not working

Verify the auth configuration:
```bash
kubectl exec -n vault $VAULT_POD -- vault read auth/kubernetes/config
kubectl exec -n vault $VAULT_POD -- vault read auth/kubernetes/role/external-secrets
```

## Security Best Practices

1. **Unseal Keys**: Store in multiple secure locations, never in Git
2. **Root Token**: Use sparingly, create specific tokens for different operations
3. **Policies**: Use least-privilege policies for each service
4. **Audit Logs**: Enable and monitor Vault audit logs
5. **Rotation**: Rotate secrets regularly (recommended: every 90 days)
6. **Backups**: Backup Vault data regularly (Raft snapshots)

## Backup and Recovery

### Creating a Snapshot

```bash
kubectl exec -n vault vault-0 -- vault operator raft snapshot save /tmp/vault-snapshot.snap
kubectl cp vault/vault-0:/tmp/vault-snapshot.snap ./vault-snapshot-$(date +%Y%m%d).snap
```

### Restoring from Snapshot

```bash
kubectl cp ./vault-snapshot.snap vault/vault-0:/tmp/vault-snapshot.snap
kubectl exec -n vault vault-0 -- vault operator raft snapshot restore /tmp/vault-snapshot.snap
```

## References

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [Vault Kubernetes Auth](https://www.vaultproject.io/docs/auth/kubernetes)
