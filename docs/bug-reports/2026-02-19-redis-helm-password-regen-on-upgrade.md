# Bug Report: Redis Password Regenerated on Helm Upgrade, Vault KV Becomes Stale

**Date:** 2026-02-19
**Severity:** High (Production Risk)
**Status:** Resolved
**Component:** Bitnami Redis Helm chart / Vault KV
**Cluster:** whispr-messenger (GKE, europe-west1-b)

## Summary

Each `helm upgrade` of the Bitnami Redis chart (v22.0.7) had the potential to auto-generate a **new** Redis password because `global.redis.password` was set to `""`. When this happens, the Kubernetes secret `redis` in namespace `redis` is overwritten with the new password, but Vault KV (`kv/whispr/shared/redis`) still holds the old value. All services that mount `REDIS_SENTINEL_PASSWORD` from that KV path start failing with `WRONGPASS`.

This was identified as **RC#1** during the 2026-02-13 incident post-mortem (see `2026-02-13-vault-redis-credential-desync.md`).

## Symptoms

- After a `helm upgrade` of the Redis chart, pods begin failing authentication to Redis Sentinel.
- `REDIS_SENTINEL_PASSWORD` obtained from Vault KV is rejected by Sentinel with `WRONGPASS`.
- Vault DB plugin (`database/config/redis`) becomes unreachable because the `default` user password has also changed.
- Cascading: `VaultDynamicSecret` renewal fails → stale ACL credentials → `WRONGPASS` across all services.

## Root Cause

The Bitnami Redis Helm chart generates and stores the Redis password in a Kubernetes secret (`redis` in namespace `redis`). When `global.redis.password: ""` is set and no `existingSecret` is referenced, the chart **generates a new random password** every time `helm upgrade` is run without the `--set` override. This behaviour is by design in the Bitnami chart.

Since the `vault-config-job` only stores the password at creation time (and the Vault KV path is not automatically updated on Helm upgrades), any subsequent Helm upgrade without an explicit password pin causes a permanent desync.

## Debugging Steps

### 1. Compare live Redis password vs Vault KV

```bash
# Live password from K8s secret
kubectl get secret redis -n redis -o jsonpath='{.data.redis-password}' | base64 -d

# Password stored in Vault KV
ROOT_TOKEN=$(kubectl get secret vault-root-token -n vault -o jsonpath='{.data.root_token}' | base64 -d)
kubectl exec -n vault vault-0 -- sh -c \
  "VAULT_TOKEN=$ROOT_TOKEN vault kv get kv/whispr/shared/redis" | grep REDIS_SENTINEL_PASSWORD
# Mismatch → root cause confirmed
```

### 2. Verify the Helm values causing the regeneration

```bash
helm get values redis -n redis | grep -A3 "global:"
# password: ""  ← triggers Bitnami auto-generation
```

## Resolution

### Fix Applied

Modified `helm/redis/values.yaml` to pin the chart to the **already-existing** Kubernetes secret instead of auto-generating a new one on each upgrade:

```yaml
# Before
global:
  redis:
    password: "" # Will be auto-generated if empty

auth:
  enabled: true
  sentinel: true
  # existingSecret: "redis-secret"
  # existingSecretPasswordKey: "redis-password"
```

```yaml
# After
global:
  redis:
    # password managed via auth.existingSecret below — do not set here
    # password: ""

auth:
  enabled: true
  sentinel: true
  # Secret 'redis' in namespace 'redis' created by Bitnami chart on first deploy
  # Key: redis-password — synced to Vault KV kv/whispr/shared/redis
  existingSecret: "redis"
  existingSecretPasswordKey: "redis-password"
```

The secret `redis` in namespace `redis` (containing key `redis-password`) was already present from the initial Bitnami deployment and contains the live password that is synced to Vault KV. By referencing it via `existingSecret`, Helm reads the password from the existing secret instead of generating a new one.

### Verification

```bash
# After helm upgrade, confirm password unchanged
kubectl get secret redis -n redis -o jsonpath='{.data.redis-password}' | base64 -d
# Must match the value previously stored in Vault KV

# Confirm Vault DB plugin can still connect
ROOT_TOKEN=$(kubectl get secret vault-root-token -n vault -o jsonpath='{.data.root_token}' | base64 -d)
kubectl exec -n vault vault-0 -- sh -c \
  "VAULT_TOKEN=$ROOT_TOKEN vault read database/config/redis"
# Should return config without error
```

## Commits

- `fix(redis): prevent credential desync between Vault and Redis` — `infrastructure` repo, `main`

## Lessons Learned

1. **Never leave `global.redis.password: ""`** in a production Bitnami Redis Helm chart if the password is externally managed (e.g. Vault KV). Always pin via `existingSecret`.

2. **Bitnami's auto-generation is idempotent only at first install.** On subsequent `helm upgrade` calls, the chart may regenerate the password if the field is empty and the secret already exists with a different structure.

3. **Helm upgrade ≠ no-op for stateful Bitnami charts.** Always audit Bitnami chart upgrade notes for password/secret handling changes.

## Affected Files

- `helm/redis/values.yaml`
