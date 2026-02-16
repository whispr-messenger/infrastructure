# Bug Report: Vault-Redis Credential Desynchronization

**Date:** 2026-02-13
**Severity:** Critical (Production)
**Status:** Resolved
**Component:** Vault Config Job / Redis / user-service
**Cluster:** whispr-messenger (GKE, europe-west1-b)

## Summary

The user-service pods entered a Degraded state (1/2 Ready) due to invalid Redis credentials. The Vault database secrets engine could no longer authenticate to Redis, preventing the generation of valid dynamic credentials for microservices.

## Symptoms

- **ArgoCD Health:** Degraded
- **Pod Status:** 1/2 Ready (istio-proxy Running, whispr-user-api Not Ready)
- **Readiness probe failing** on `/user/v1/health/ready` with HTTP 503

Application logs:

```
[Nest] 1  - 02/13/2026, 3:39:18 PM   ERROR [HealthController] Readiness check failed:
WRONGPASS invalid username-password pair or user is disabled.
[Nest] 1  - 02/13/2026, 3:39:18 PM   ERROR [LoggingInterceptor] Request Error: GET /user/v1/health/ready - Status: 503  - Duration: 4ms - Error: Service Unavailable Exception
```

## Root Cause

A chain of three failures caused credential desynchronization between Vault and Redis:

1. **Bitnami Redis password regeneration:** The Bitnami Redis Sentinel Helm chart (redis-22.0.7) regenerated its `default` user password during an upgrade or pod restart. The new password was stored in the Kubernetes secret `redis` in namespace `redis`.

2. **Stale Vault configuration:** The `vault-config-job` (ArgoCD PostSync hook) was configured to skip Redis configuration if already present (idempotent guard). This meant Vault retained the old password and could no longer connect to Redis.

3. **rotate-root incompatibility:** An initial fix attempted to use `vault write -f database/rotate-root/redis` after re-syncing the password. This is incompatible with Bitnami Redis Sentinel: Vault changes the `default` user password via `ACL SETUSER`, but Bitnami overrides it on restart from the mounted secret file, permanently breaking Vault's connection.

**Result:** Vault could not authenticate to Redis, `database/creds/redis_role_*` calls failed with `context deadline exceeded`, and the `VaultDynamicSecret` resources could not populate valid Kubernetes secrets.

## Debugging Steps

### 1. Verify Pod State

```bash
kubectl get pods -n whispr-prod -l app=user-service
# Output: user-service-xxx  1/2  Running
```

### 2. Check Application Logs

```bash
kubectl logs -n whispr-prod <pod> -c whispr-user-api | grep -i error
# Output: WRONGPASS invalid username-password pair or user is disabled
```

### 3. Test Redis ACL Users

```bash
kubectl exec redis-node-0 -n redis -c redis -- redis-cli -a '<password>' ACL LIST
# Result: Only the 'default' user existed. Dynamic Vault user was missing.
```

### 4. Test Vault Credential Generation

```bash
kubectl exec vault-0 -n vault -- sh -c \
  'VAULT_TOKEN=<token> vault read database/creds/redis_role_user_service'
# Result: Error reading database/creds/redis_role_user_service: context deadline exceeded
```

### 5. Verify Vault-to-Redis Connectivity

```bash
kubectl exec vault-0 -n vault -- sh -c 'nc -zv redis.redis.svc.cluster.local 6379 -w 5'
# Result: Connection open (network is fine)
```

### 6. Confirm Password Mismatch

```bash
kubectl exec vault-0 -n vault -- sh -c \
  'VAULT_TOKEN=<token> vault write -f database/config/redis'
# Result: Code 400 - error verifying connection: WRONGPASS invalid username-password pair
```

## Resolution

### Fix Applied

Modified `k8s/vault/vault-config-job.yaml` to:

1. **Always re-sync** the Redis password from the Kubernetes secret on every config job run (no idempotent guard for Redis, unlike PostgreSQL).
2. **Use `verify_connection=true`** to fail fast if the password is wrong.
3. **Remove `rotate-root`** entirely for Redis to avoid conflicts with Bitnami's password management.

```bash
# Redis configuration (re-syncs password from K8s secret on every run)
REDIS_PASSWORD=$(kubectl get secret -n redis redis -o jsonpath='{.data.redis-password}' | base64 -d)

vault write database/config/redis \
  plugin_name=redis-database-plugin \
  allowed_roles="*" \
  host=redis.redis.svc.cluster.local \
  port=6379 \
  username="default" \
  password="$REDIS_PASSWORD" \
  verify_connection=true
```

The PostgreSQL configuration remains idempotent (skip if already configured) since it does not suffer from the same Bitnami password rotation issue.

### RBAC Prerequisite

The `vault-config` service account requires a `ClusterRole` with `get`/`list` on secrets to read the Redis password from the `redis` namespace:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: vault-config-cross-ns-reader
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
```

### Verification

```bash
# Force ArgoCD sync to trigger the config job
argocd app sync argocd/vault-config

# Delete stale secret to force VSO regeneration
kubectl delete secret user-service-redis-secret -n whispr-prod

# Verify new credentials are generated
kubectl exec vault-0 -n vault -- sh -c \
  'VAULT_TOKEN=<token> vault read database/creds/redis_role_user_service'
# Success: username=V_ROOT_REDIS_ROLE_USER_SERVICE_xxx, password=<generated>

# Confirm pods are healthy
kubectl get pods -n whispr-prod -l app=user-service
# Output: user-service-xxx  2/2  Running
```

## Commits

1. `fix(vault): make Redis and PostgreSQL database config idempotent` (intermediate, later revised)
2. `fix(vault): remove rotate-root and re-sync Redis password on every run` (final fix)

## Lessons Learned

1. **Vault rotate-root is incompatible with Bitnami Redis Sentinel.** Bitnami manages the `default` user password via mounted secret files and overrides any ACL changes on pod restart.

2. **Redis config must be re-synced on every run.** Unlike PostgreSQL (where the admin password is stable), the Bitnami Redis password can change during Helm upgrades or pod restarts. The config job must always overwrite Vault's stored password with the current value from the Kubernetes secret.

3. **Dynamic credentials require a healthy root connection.** If Vault loses its connection to the backing store, all downstream `VaultDynamicSecret` resources fail silently (secrets contain stale data) until the next renewal attempt, at which point pods lose connectivity.

## Affected Files

- `k8s/vault/vault-config-job.yaml`
- `k8s/vault/vault-config-rbac.yaml`
