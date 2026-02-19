# Bug Report: Vault Stores Stale Redis Master IP After Sentinel Failover

**Date:** 2026-02-19
**Severity:** High (Production Risk)
**Status:** Resolved
**Component:** Vault Config Job / Redis Sentinel / Vault DB Plugin
**Cluster:** whispr-messenger (GKE, europe-west1-b)

## Summary

The `vault-bootstrap-job` discovers the Redis master by querying Sentinel (via `SENTINEL get-master-addr-by-name mymaster`) and writes the result directly into `vault write database/config/redis host="$MASTER_HOST"`. Sentinel returns a **raw IP address**. This IP is stable as long as the current master pod is alive, but becomes **stale after a Sentinel failover**: the new elected master has a different pod IP, and Vault continues trying to connect to the old (potentially dead) pod IP. This causes all `database/creds/redis_role_*` requests to time out.

This was identified as **RC#2** during the 2026-02-13 incident post-mortem (see `2026-02-13-vault-redis-credential-desync.md`).

## Symptoms

- After a Redis Sentinel failover (e.g. master pod eviction, node maintenance), Vault cannot connect to Redis.
- `vault read database/creds/redis_role_<service>` returns `context deadline exceeded`.
- The `VaultDynamicSecret` renewable cycle fails → stale ACL credentials remain in Kubernetes secrets.
- Pods start logging `WRONGPASS invalid username-password pair or user is disabled`.

## Root Cause

After a Sentinel failover, the elected master is a different pod with a different IP. Pod IPs in Kubernetes are ephemeral and tied to the pod lifecycle. The `vault-bootstrap-job` is a one-shot Kubernetes `Job` (ArgoCD PostSync hook) that runs once at install time. It does not re-run on failovers.

In the original implementation:

```bash
MASTER_HOST=$(redis-cli -h redis.redis.svc.cluster.local -p 26379 \
  -a "$REDIS_PASSWORD" --no-auth-warning \
  SENTINEL get-master-addr-by-name mymaster 2>/dev/null | head -1)
# Returns e.g. "10.24.1.47" → ephemeral pod IP
vault write database/config/redis host="$MASTER_HOST" ...
# Stored value: 10.24.1.47 — becomes stale after failover
```

After a failover, `10.24.1.47` may no longer exist or may belong to a replica. Vault attempts to open an authenticated connection to this IP and times out.

### Why not use `redis.redis.svc.cluster.local`?

The `redis` ClusterIP service in namespace `redis` routes traffic to **all** nodes (master and replicas), not exclusively to the master. Vault's Redis DB plugin needs to issue `ACL SETUSER` commands to create dynamic credentials, which are **only accepted by the master** (replicas return `READONLY`). Using the ClusterIP is unreliable for write operations.

## Debugging Steps

### 1. Identify the stored master host in Vault

```bash
ROOT_TOKEN=$(kubectl get secret vault-root-token -n vault -o jsonpath='{.data.root_token}' | base64 -d)
kubectl exec -n vault vault-0 -- sh -c \
  "VAULT_TOKEN=$ROOT_TOKEN vault read database/config/redis" | grep host
# e.g. host: 10.24.1.47
```

### 2. Identify the current Redis master

```bash
redis-cli -h redis.redis.svc.cluster.local -p 26379 \
  -a "$(kubectl get secret redis -n redis -o jsonpath='{.data.redis-password}' | base64 -d)" \
  --no-auth-warning SENTINEL get-master-addr-by-name mymaster
# e.g. 10.24.2.11  ← different from what Vault has
```

### 3. Verify the IP is stale

```bash
kubectl get pods -n redis -o wide | grep 10.24.1.47
# No output — pod no longer exists
```

### 4. Confirm Vault cannot generate credentials

```bash
kubectl exec -n vault vault-0 -- sh -c \
  "VAULT_TOKEN=$ROOT_TOKEN vault read database/creds/redis_role_auth_service"
# Error: context deadline exceeded
```

## Resolution

### Fix Applied

Modified `k8s/vault/vault-bootstrap-job.yaml` to map the Sentinel-reported IP to its **stable pod DNS hostname** via the headless service `redis-headless`:

```bash
# Before
MASTER_HOST=$(redis-cli ... SENTINEL get-master-addr-by-name mymaster | head -1)
# Returns e.g. "10.24.1.47" (ephemeral IP)
```

```bash
# After
MASTER_IP=$(redis-cli ... SENTINEL get-master-addr-by-name mymaster | head -1)

if [ -z "$MASTER_IP" ]; then
  echo "WARNING: Sentinel discovery failed, falling back to ClusterIP service"
  MASTER_HOST="redis.redis.svc.cluster.local"
else
  # Map IP → pod name → stable headless DNS
  MASTER_POD=$(kubectl get pods -n redis -o wide --no-headers \
    | awk -v ip="$MASTER_IP" '$6 == ip {print $1}')
  if [ -n "$MASTER_POD" ]; then
    MASTER_HOST="${MASTER_POD}.redis-headless.redis.svc.cluster.local"
    # e.g. redis-node-0.redis-headless.redis.svc.cluster.local
  else
    MASTER_HOST="$MASTER_IP"  # fallback: use IP if pod lookup fails
  fi
fi

vault write database/config/redis host="$MASTER_HOST" ...
```

The headless service `redis-headless` creates a stable DNS entry per pod (`<pod-name>.redis-headless.<namespace>.svc.cluster.local`) that always resolves to the correct pod IP, even after restarts. This hostname is predictable and pod IP changes are transparent to Vault at connection time.

### RBAC Prerequisite

The `vault-config-redis-reader` ClusterRole was already configured with `pods: get, list` on namespace `redis`, so no additional RBAC changes were needed.

### Why this does not fully eliminate re-run risk

If a **second failover** occurs after the bootstrap job runs, the stored hostname (e.g. `redis-node-0.redis-headless...`) may still point to a node that is no longer master. Vault's DB plugin write operations will then hit a replica and fail with `READONLY`.

**Long-term mitigation (not yet implemented):** A CronJob that periodically re-runs the Sentinel discovery → pod DNS resolution → `vault write database/config/redis` update to keep Vault in sync with the current master.

### Verification

```bash
# Trigger re-run of the config job
kubectl delete job vault-bootstrap-job -n vault 2>/dev/null
argocd app sync argocd/vault-config

# Verify the new stored host
ROOT_TOKEN=$(kubectl get secret vault-root-token -n vault -o jsonpath='{.data.root_token}' | base64 -d)
kubectl exec -n vault vault-0 -- sh -c \
  "VAULT_TOKEN=$ROOT_TOKEN vault read database/config/redis" | grep host
# e.g. host: redis-node-0.redis-headless.redis.svc.cluster.local

# Confirm credential generation works
kubectl exec -n vault vault-0 -- sh -c \
  "VAULT_TOKEN=$ROOT_TOKEN vault read database/creds/redis_role_auth_service"
# Should return a valid username/password pair
```

## Commits

- `fix(redis): prevent credential desync between Vault and Redis` — `infrastructure` repo, `main`

## Lessons Learned

1. **Never store ephemeral pod IPs in persistent configuration.** Sentinel's `get-master-addr-by-name` returns the current pod IP, which changes on every pod restart or failover. Always map to a stable DNS hostname.

2. **The `redis-headless` service provides stable per-pod DNS.** `<pod>.redis-headless.<ns>.svc.cluster.local` is the correct way to address individual Redis pods durably in Kubernetes.

3. **One-shot Jobs don't track topology changes.** A bootstrap job is appropriate for initial setup but must be complemented by a periodic reconciliation mechanism (CronJob or ArgoCD sync wave hook) for components sensitive to topology changes like Redis master election.

4. **The ClusterIP Redis service is write-unsafe.** It load-balances across all nodes; write commands to a replica return `READONLY`. Only use it for read operations or Sentinel queries (port 26379).

## Affected Files

- `k8s/vault/vault-bootstrap-job.yaml`
