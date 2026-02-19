# Bug Report: Redis ACL Users Wiped on Pod Restart — VSO Credentials Become WRONGPASS

**Date:** 2026-02-19
**Severity:** Critical (Production)
**Status:** Resolved
**Component:** Vault Secrets Operator / Redis ACL / vault-redis-master-sync
**Cluster:** whispr-messenger (GKE, europe-west1-b)

## Summary

Following the restart of `redis-node-0` and `redis-node-1` (StatefulSet rolling update), all Vault-generated Redis ACL users were silently wiped from memory. The Vault Secrets Operator (VSO) continued to renew the Vault lease TTL for existing credentials but never re-issued them — meaning it never triggered `ACL SETUSER` again on the new Redis master. The application pods held Kubernetes secrets containing usernames that no longer existed in Redis, resulting in a permanent `WRONGPASS` authentication failure.

`auth-service` and `user-service` entered readiness failure (`HTTP 503`). The VSO `VaultDynamicSecret` CRs showed `Healthy` and reported successful lease renewals, masking the underlying issue.

## Symptoms

- **Pod readiness:** `auth-service` and `user-service` failing `/health/ready` with 503.
- **Application logs** (both services):

```
[Nest] 1  ERROR [RedisConfig] ReplyError: WRONGPASS invalid username-password pair or user is disabled.
  command: { name: 'auth', args: [ 'V_KUBERNETES-WHISPR-PROD-AUTH-SERVICE-SA_REDIS_ROLE_AUTH_SERVICE_HC2SF2AC41BLYERPZKJT_1771495428', 'aWUCC5wNlJWQCYlNQ-d3' ] }

[Nest] 1  ERROR [RedisConfig] Error: All sentinels are unreachable. Retrying from scratch after 10ms.

[Nest] 1  ERROR [HealthController] Readiness check failed: WRONGPASS invalid username-password pair or user is disabled.
```

- **VSO CRs status:** `SecretSynced: True`, `LeaseRenewal: True`, `Healthy: True` — no error visible.
- `redis-node-0` and `redis-node-1` restarted ~39 minutes before the incident was detected.

## Root Cause

### 1. Redis ACL is in-memory only — no `aclfile` configured

The Bitnami Redis chart does not configure an `aclfile`. All ACL users created at runtime (`ACL SETUSER`) are held in memory. When a Redis pod restarts, the in-memory ACL table is rebuilt from scratch using only the `requirepass` / `default` user from the mounted config. All Vault-generated users (`V_*_REDIS_ROLE_*`) are permanently lost.

### 2. VSO renews leases but does not re-create ACL users

When VSO renews a Vault lease (before `renewalPercent` of the TTL), it calls `PUT /v1/sys/leases/renew/:lease_id` against the Vault API. This extends the TTL of the existing Vault credential, but does **not** re-issue the credential. The Redis database plugin only runs `ACL SETUSER` when a new credential is created (`GET /v1/database/creds/:role`), not on renewal. After a Redis restart, the stale lease remains valid in Vault, but the ACL user it corresponds to no longer exists in Redis.

### 3. No automation to detect and recover from the ACL drift

The `vault-redis-master-sync` CronJob previously exited early (`exit 0`) when the Redis master host was unchanged, so Step 6 (ACL health-check) was not yet implemented. There was no mechanism to compare the Redis `ACL LIST` against the set of expected Vault-issued users, nor to trigger credential rotation.

## Timeline

| Time | Event |
|------|-------|
| ~13:10 | `redis-node-0` and `redis-node-1` restarted (StatefulSet rolling update) |
| ~13:10 | All Vault ACL users wiped from Redis memory |
| ~13:10 | `vault-bootstrap-job` PostSync hook re-ran (ArgoCD sync wave 5), creating fresh `V_ROOT_*` ACL users |
| ~13:10 | VSO continued renewing the pre-existing leases — no new `ACL SETUSER` for `V_KUBERNETES-*` users |
| ~13:48 | `WRONGPASS` detected in `auth-service` and `user-service` logs |
| ~13:48 | Investigation started |

## Debugging Steps

### 1. Identify the error from application logs

```bash
kubectl logs -n whispr-prod deploy/auth-service --tail=80
# Output: WRONGPASS invalid username-password pair or user is disabled.
# ACL AUTH command args reveal the specific username: V_KUBERNETES-..._1771495428
```

### 2. Confirm VSO appeared healthy

```bash
kubectl get vaultdynamicsecrets.secrets.hashicorp.com -n whispr-prod
kubectl describe vaultdynamicsecrets.secrets.hashicorp.com auth-service-redis-creds -n whispr-prod
# Status: SecretSynced=True, LeaseRenewal=True, Healthy=True
# Last Renewal: 1771508356 — lease actively renewed, no error
```

### 3. Verify the Redis ACL table

```bash
REDIS_PASSWORD=$(kubectl get secret redis -n redis -o jsonpath='{.data.redis-password}' | base64 -d)
kubectl exec -n redis redis-node-1 -- redis-cli -p 6379 -a "$REDIS_PASSWORD" --no-auth-warning ACL LIST
# Output: only V_ROOT_* users — no V_KUBERNETES-* users for auth-service or user-service
```

### 4. Confirm redis-node-0 and redis-node-1 restarted recently

```bash
kubectl get events -n redis --sort-by='.lastTimestamp' | grep -E "Killing|Started"
# Output: redis-node-0 and redis-node-1 killed and restarted ~39 minutes ago
```

### 5. Confirm no aclfile is configured

```bash
kubectl exec -n redis redis-node-1 -- redis-cli -p 6379 -a "$REDIS_PASSWORD" --no-auth-warning CONFIG GET aclfile
# Output: aclfile → (empty string) — ACL is in-memory only
```

### 6. Verify the credential in the Kubernetes secret is stale

```bash
kubectl get secret auth-service-redis-secret -n whispr-prod -o jsonpath='{.data.username}' | base64 -d
# Output: V_KUBERNETES-WHISPR-PROD-AUTH-SERVICE-SA_REDIS_ROLE_AUTH_SERVICE_HC2SF2AC41BLYERPZKJT_1771495428
# This user does not appear in ACL LIST — it was wiped with the restart at 13:10
```

## Fix

### Immediate (cluster recovery)

Delete the stale Kubernetes secrets to force VSO to re-request credentials from Vault. This triggers a new `ACL SETUSER` on the Redis master and registers fresh usernames.

```bash
kubectl delete secret auth-service-redis-secret user-service-redis-secret -n whispr-prod
# VSO regenerates both secrets within <10s (rolloutRestartTargets triggers pod rolling restart)
```

Confirmed recovery:

```
auth-service /auth/v1/health/ready → HTTP 200 ✅
user-service /user/v1/health/ready → HTTP 200 ✅
```

### Structural (manifests — commit `2013d5d`)

Two manifest changes were committed to prevent recurrence:

#### 1. `k8s/vault/vault-rbac.yaml` — new Role in `whispr-prod`

Added `vault-config-whispr-redis-health` Role and RoleBinding granting the `vault-config` ServiceAccount (namespace `vault`) permission to `delete` the five Redis credential secrets in `whispr-prod`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: vault-config-whispr-redis-health
  namespace: whispr-prod
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames:
      - auth-service-redis-secret
      - user-service-redis-secret
      - media-service-redis-secret
      - messaging-service-redis-secret
      - scheduling-service-redis-secret
    verbs: ["delete"]
```

#### 2. `k8s/vault/vault-redis-master-sync.yaml` — Step 6 ACL health-check

- Removed the early `exit 0` on master-unchanged path so the CronJob always reaches Step 6.
- Added Step 6: reads `ACL LIST` from the current Redis master, checks for a `V_*_REDIS_ROLE_<SERVICE>` entry for each of the five services, and deletes the stale K8s secret if the user is absent. VSO then re-requests credentials, which re-creates the ACL user.

```bash
# Step 6: ACL health check
ACL_LIST=$(redis-cli -h "$NEW_MASTER" -p 6379 -a "$REDIS_PASSWORD" --no-auth-warning ACL LIST)
for svc in auth-service user-service media-service messaging-service scheduling-service; do
  svc_upper=$(echo "$svc" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  if echo "$ACL_LIST" | grep -qi "V_.*REDIS_ROLE_${svc_upper}"; then
    echo "ACL user for $svc: OK"
  else
    kubectl delete secret "${svc}-redis-secret" -n whispr-prod --ignore-not-found=true
    # VSO detects the missing secret and re-issues the credential from Vault
  fi
done
```

**Recovery window after Redis restart: ≤5 min** (next CronJob tick).

#### Validation

The updated CronJob was tested immediately after deployment:

```
=== vault-redis-master-sync ===
Master unchanged (redis-node-1.redis-headless.redis.svc.cluster.local), skipping Vault DB update.
=== Step 6: ACL health check ===
ACL user for auth-service: OK
ACL user for user-service: OK
WARNING: No ACL user found for media-service. Deleting media-service-redis-secret to force VSO rotation...
secret "media-service-redis-secret" deleted
Deleted media-service-redis-secret — VSO will regenerate and register a fresh ACL user.
WARNING: No ACL user found for messaging-service. Deleting messaging-service-redis-secret to force VSO rotation...
...
=== vault-redis-master-sync completed ===
```

Step 6 also auto-detected and self-healed `media-service`, `messaging-service`, and `scheduling-service`, which had the same stale ACL user problem.

## Residual Risk

- **`aclfile` not configured:** Redis ACL users will still be wiped on every pod restart. The CronJob mitigates this within ≤5 min, but there is a brief window where the credential is invalid. A longer-term fix would be to add `aclfile /data/users.acl` to the Redis configmap and `ACL SAVE` periodically, making the ACL table durable across restarts. This was not implemented to avoid modifying the Bitnami chart's data volume layout.
- **Sentinel `announce-hostname` cosmetic warning:** The Step 3 master-mapping log prints `WARNING: Could not map IP <fqdn> to a pod` when Bitnami Sentinel is configured with `announce-hostname` (returns the FQDN directly instead of a raw IP). The fallback path correctly uses the FQDN; the warning is misleading. No functional impact.

## Related Reports

- [2026-02-13-vault-redis-credential-desync.md](2026-02-13-vault-redis-credential-desync.md) — initial desync incident (Bitnami password regen)
- [2026-02-19-redis-helm-password-regen-on-upgrade.md](2026-02-19-redis-helm-password-regen-on-upgrade.md) — RC#1 (existingSecret not preserved by ArgoCD prune)
- [2026-02-19-vault-redis-stale-master-host-after-failover.md](2026-02-19-vault-redis-stale-master-host-after-failover.md) — RC#2 (ephemeral pod IP stored in Vault DB engine)
