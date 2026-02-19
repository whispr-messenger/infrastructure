# Bug Report: auth-service Has No Redis Sentinel Support and Silent Health Check

**Date:** 2026-02-19
**Severity:** High (Production Risk)
**Status:** Resolved
**Component:** auth-service / Redis cache layer
**Cluster:** whispr-messenger (GKE, europe-west1-b)
**Branch:** `WHISPR-269/redis-vault-integration`

## Summary

Two related issues were discovered in `auth-service` following the 2026-02-13 incident post-mortem:

1. **No Sentinel support:** `auth-service` used `@keyv/redis` + `@nestjs/cache-manager` v7, a stack that connects to Redis via a single direct host:port. In a Sentinel-managed cluster, this means the service connects to a hardcoded host, cannot follow master re-elections, and will start failing after the first failover.

2. **Silent health check:** `/health/ready` returned HTTP 200 even when the Redis connection was broken, masking the outage from ArgoCD, Kubernetes readiness probes, and load balancers. This was the opposite of the correct behaviour (HTTP 503).

## Symptoms

### Sentinel support missing

- After a Redis master failover, `auth-service` tokens, phone verification codes, and QR code nonces become inaccessible.
- Cache reads return `null` (miss) instead of `WRONGPASS` or connection errors because `@keyv/redis` silently swallows connection errors.
- The service continues to appear healthy (200 on `/health/ready`).

### Silent health check

- `kubectl get pods -n whispr-prod -l app=auth-service` shows `2/2 Running` during a Redis outage.
- ArgoCD reports health as `Healthy` instead of `Degraded`.
- On-call engineers are not alerted because no pod enters `NotReady` state.

Application logs during outage:

```
[Nest] - ERROR [HealthController] Redis check: Error: connect ECONNREFUSED
[Nest] - LOG   [HealthController] GET /health/ready - 200 OK  ← wrong
```

## Root Cause

### 1. Library stack does not support Sentinel

`@keyv/redis` (wrapping the `redis` npm client) requires a single `host:port` connection string. The `REDIS_URL` environment variable was set to `redis://redis.redis.svc.cluster.local:6379`, which routes to the Bitnami ClusterIP service. After failover, if the new master is a different pod, write operations fail because `redis.redis.svc.cluster.local:6379` may route to a replica returning `READONLY`.

The correct approach for a Bitnami Redis Sentinel cluster is to connect via the Sentinel protocol: provide a list of Sentinel hosts, request the `mymaster` group, and let the client handle master re-election automatically.

### 2. Health endpoint swallowed errors

```typescript
// Before — in health.controller.ts
@Get('ready')
async readiness(): Promise<HealthStatus> {
  try {
    const checks = await Promise.all([...]);
    return { status: 'ok', ... };
  } catch (error) {
    // Logged but returned 200 — controller never re-threw
    this.logger.error('Readiness check failed:', error.message);
    return { status: 'error', ... }; // still 200
  }
}
```

Kubernetes readiness probes only mark a pod `NotReady` on non-2xx responses. Returning 200 with `status: 'error'` in the body has no effect on pod scheduling or traffic routing.

## Resolution

### Fix 1 — Migrate to ioredis with Sentinel support

Replaced `@keyv/redis` + `@nestjs/cache-manager` with `ioredis` (same client used by `user-service`).

**Uninstalled:**
- `@keyv/redis`
- `@nestjs/cache-manager`
- `cache-manager`
- `redis`

**Installed:**
- `ioredis@^5.9.2`

New files:

- `src/config/redis.config.ts` — `RedisConfig` injectable; reads `REDIS_MODE` (`direct` | `sentinel`), `REDIS_SENTINELS` (comma-separated `host:port` list), `REDIS_MASTER_NAME`, `REDIS_SENTINEL_PASSWORD`; tracks health via ioredis events (`error/ready/connect/close`); exposes `buildRedisOptions()` and `getClient()`.

- `src/cache/cache.service.ts` — `CacheService` wrapping ioredis: `set/get/del/delMany/exists/expire/keys/incr/decr/pipeline`. Handles JSON serialization internally (callers work directly with typed objects).

- `src/cache/cache.module.ts` — `@Global()` NestJS module providing `RedisConfig` and `CacheService` to the entire application.

**Environment variables (production, from `VaultStaticSecret`):**

```
REDIS_MODE=sentinel
REDIS_SENTINELS=redis-node-0.redis-headless.redis.svc.cluster.local:26379,...
REDIS_MASTER_NAME=mymaster
REDIS_SENTINEL_PASSWORD=<from Vault KV kv/whispr/shared/redis>
```

### Fix 2 — Health endpoint returns 503 on Redis failure

```typescript
// After — health.controller.ts
@Get('ready')
async readiness(): Promise<HealthStatus> {
  try {
    await this.checkCacheHealth();
    await this.checkDatabaseHealth();
    return { status: 'ok', ... };
  } catch (error) {
    this.logger.error('Readiness check failed:', error.message);
    throw new ServiceUnavailableException({ status: 'error', ... });
    // → HTTP 503 → pod enters NotReady → traffic stops → alert fires
  }
}

private async checkCacheHealth(): Promise<void> {
  if (!this.redisConfig.health.isHealthy) {
    throw new Error(`Redis unhealthy: ${this.redisConfig.health.lastError}`);
  }
  await this.cacheService.set('health-check', 'ok', 10);
  const val = await this.cacheService.get<string>('health-check');
  if (val !== 'ok') throw new Error('Redis round-trip failed');
}
```

### TTL unit change

`@nestjs/cache-manager` v7 uses **milliseconds** for TTL; `ioredis` (and `CacheService`) uses **seconds**. All call sites were updated:

| Before | After |
|---|---|
| `cacheManager.set(key, val, REFRESH_TOKEN_TTL * 1000)` | `cacheService.set(key, val, REFRESH_TOKEN_TTL)` |
| `cacheManager.set(key, val, RATE_LIMIT_TTL * 1000)` | `cacheService.set(key, val, RATE_LIMIT_TTL)` |
| `Math.ceil(expiresAt - Date.now())` (ms) | `Math.ceil((expiresAt - Date.now()) / 1000)` (s) |

### Verification

```bash
# Confirm auth-service pod enters NotReady when Redis is unreachable
kubectl exec -n redis redis-node-0 -c redis -- redis-cli -p 6379 DEBUG sleep 30
# Within 30s:
kubectl get pods -n whispr-prod -l app=auth-service
# Expected: 1/2 (0/1 for main container — NotReady)

# Confirm Sentinel failover is followed
kubectl delete pod redis-node-0 -n redis  # force failover
kubectl exec -n redis redis-node-1 -c redis -- \
  redis-cli -p 26379 SENTINEL masters | grep -A1 "is-master-down"
# New master should be node-1 or node-2
# auth-service tokens should remain accessible after failover
```

## Commits

- `feat(cache): migrate from @keyv/redis to ioredis with Sentinel support` — `auth-service` repo, branch `WHISPR-269/redis-vault-integration`

## Lessons Learned

1. **`@keyv/redis` and `cache-manager` do not support Sentinel.** Any NestJS service using `@nestjs/cache-manager` with a Sentinel Redis cluster must be migrated to a Sentinel-aware client (`ioredis`, `ioredis-sentinel`, or `@redis/client` with Sentinel URL).

2. **Health endpoints must return 5xx to be useful.** A `{ status: 'error' }` body with HTTP 200 is invisible to Kubernetes, ArgoCD, and Istio. Always throw `ServiceUnavailableException` (503) when a critical dependency is down.

3. **TTL units differ between cache libraries.** `cache-manager` v7 and above uses milliseconds; `ioredis` uses seconds. Mixing the two leads to tokens expiring 1000× too late or too early.

4. **Mirror the user-service pattern.** `user-service` already used `ioredis` with Sentinel natively. New NestJS services should copy that pattern directly rather than starting from `@nestjs/cache-manager`.

## Affected Files

### `auth-service`
- `src/config/redis.config.ts` *(new)*
- `src/cache/cache.service.ts` *(new)*
- `src/cache/cache.module.ts` *(new)*
- `src/cache/index.ts` *(new)*
- `src/modules/app/app.module.ts`
- `src/modules/app/cache.ts`
- `src/modules/health/health.controller.ts`
- `src/modules/health/health.module.ts`
- `src/modules/tokens/services/tokens.service.ts`
- `src/modules/tokens/tokens.module.ts`
- `src/modules/authentication/auth.module.ts`
- `src/modules/phone-verification/services/phone-verification/phone-verification.service.ts`
- `src/modules/devices/quick-response-code/quick-response-code.service.ts`
- `src/modules/tokens/services/tokens.service.spec.ts`
- `test/app.e2e-spec.ts`
- `test/registration.e2e-spec.ts`
- `package.json` / `package-lock.json`
