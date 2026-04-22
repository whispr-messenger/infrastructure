# calls-service (preprod)

Elixir/Phoenix voice/video calls backend integrated with LiveKit SFU.

Sources:
- Deployment: `deployment.yaml`
- Service (ClusterIP): `service.yaml`
- Ingress (nginx + cert-manager): `ingress.yaml`
- HPA: `hpa.yaml`
- Migration job (ArgoCD PreSync hook): `migration-job.yaml`

Public endpoint: `https://calls-preprod.roadmvn.com` (REST + WebSocket)

Namespace: `whispr-preprod`
Port: `4012` (HTTP), `40012` (gRPC)

## Prerequisites

### 1. DNS

`calls-preprod.roadmvn.com` must resolve to the cluster ingress IP (add the
record on Cloudflare before the first ArgoCD sync so the cert can be issued).

### 2. LiveKit bootstrap (WHISPR-1095)

LiveKit must be up and reachable at `livekit-preprod.roadmvn.com` with an
API key pair populated in the `livekit-keys` secret. See
`../livekit/README.md` for the full bootstrap procedure.

### 3. Secrets

Three secrets must exist in `whispr-preprod` before the first ArgoCD sync.

#### `calls-preprod-db` - Postgres connection string

```bash
kubectl -n whispr-preprod create secret generic calls-preprod-db \
  --from-literal=url='ecto://USER:PASS@postgresql.postgresql.svc.cluster.local:5432/whispr_calls'
```

The DB `whispr_calls` must be created on the shared Postgres first:

```bash
kubectl -n postgresql exec -it postgresql-0 -- \
  psql -U postgres -c "CREATE DATABASE whispr_calls;"
```

#### `calls-preprod-secrets` - Phoenix secret_key_base

```bash
SECRET_KEY_BASE=$(openssl rand -base64 48)
kubectl -n whispr-preprod create secret generic calls-preprod-secrets \
  --from-literal=secret_key_base="$SECRET_KEY_BASE"
```

#### `livekit-keys` - shared with LiveKit

Already created as part of the LiveKit bootstrap (see `../livekit/README.md`).
The calls-service reuses the same secret keys `api-key` and `api-secret`.

#### `redis-preprod` - shared Redis credentials

Already created for the other preprod services (auth, messaging, user). The
secret must expose `username` and `password` keys for the shared Bitnami
Redis cluster.

## Environment variables

All env vars are wired in `deployment.yaml` via `env:` entries, no ConfigMap
for now (preprod is simple, prod will split). Key pointers:

- `DATABASE_URL` from `calls-preprod-db`
- `SECRET_KEY_BASE` from `calls-preprod-secrets`
- `REDIS_SENTINEL_URLS`, `REDIS_SENTINEL_MASTER`, `REDIS_USERNAME`,
  `REDIS_PASSWORD` - same pattern as the other Elixir services
- `JWT_JWKS_URL=http://auth-service-preprod:3010/.well-known/jwks.json`
- `LIVEKIT_API_URL=http://livekit-server.whispr-preprod:7880`
- `LIVEKIT_PUBLIC_URL=wss://livekit-preprod.roadmvn.com`
- `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` / `LIVEKIT_WEBHOOK_SECRET` from
  `livekit-keys`
- `MESSAGING_GRPC_ENDPOINT=messaging-service:40010` - used to verify group
  membership before starting a call

## Image tag

Uses rolling tag `:preprod` (see WHISPR-1014 pattern). The calls-service CI
must push a `:preprod` tag on every green build of `main` before this
Application can sync successfully.

## References

- WHISPR-1095 - LiveKit bootstrap
- WHISPR-1010 - liveness + readiness probes homogenization
- WHISPR-1011 - BEAM Elixir resource sizing
- WHISPR-1014 - rolling preprod tag convention
- WHISPR-1066 - HPA autoscaling policy
