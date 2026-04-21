# LiveKit (preprod)

Self-hosted LiveKit SFU for the Whispr calls-service.

Sources:
- Helm chart: `livekit-server` from https://helm.livekit.io (chart version
  pinned in `argocd-preprod-citadel/applications/livekit.yaml`)
- Local Helm values: `helm-values.yaml` in this folder
- Ingress (nginx + cert-manager): `ingress.yaml` in this folder

Public endpoint: `https://livekit-preprod.roadmvn.com` (WSS on 443, via
nginx-ingress + Let's Encrypt)

Namespace: `whispr-preprod`

## Ports

| Port         | Protocol | Use                                              |
|--------------|----------|--------------------------------------------------|
| 7880         | TCP      | HTTP/WS API (containerPort, behind nginx)        |
| 7881         | TCP      | ICE/TCP fallback (hostPort, published on node)   |
| 7882         | UDP      | RTC UDP single port (hostPort, published on node)|
| 30000-30100  | UDP      | RTC media (published via hostNetwork)            |

LiveKit runs with `hostNetwork: true` (chart default), so all ports bind
directly on the node. This means only **one** LiveKit replica per node -
`replicaCount: 1` is enforced in `helm-values.yaml`.

Ports 7881 / 7882 / 30000-30100 UDP are OUTSIDE the k3s NodePort range
(30110-30200) used by the other preprod services, so there is no conflict.

## Manual bootstrap (run once per cluster)

### 1. API keys (REQUIRED before first traffic)

LiveKit needs an `api-key` / `api-secret` pair to sign room tokens. The
calls-service backend must share the same pair.

Generate a key pair:

```bash
API_KEY="APIkey$(openssl rand -hex 6)"
API_SECRET=$(openssl rand -base64 40 | tr -d '/+=' | head -c 64)
echo "API_KEY=$API_KEY"
echo "API_SECRET=$API_SECRET"
```

Inject the pair into the chart-rendered ConfigMap (one-shot patch). The
cleanest path is to add them via the ArgoCD Application's `helm.parameters`
block (see `argocd-preprod-citadel/applications/livekit.yaml`). After the
values are committed, ArgoCD will re-render the ConfigMap with the real
keys.

If the admin prefers not to commit real keys to git at all, create an
external secret and patch the ConfigMap manually:

```bash
kubectl create secret generic livekit-keys \
  --from-literal=api-key=$API_KEY \
  --from-literal=api-secret=$API_SECRET \
  -n whispr-preprod

# one-shot ConfigMap patch - ArgoCD will overwrite on next sync, so add
# `ignoreDifferences` on the Application if you keep the patch long-term
kubectl -n whispr-preprod patch configmap livekit-server --type merge -p "$(cat <<EOF
data:
  config.yaml: |
    log_level: info
    port: 7880
    keys:
      $API_KEY: $API_SECRET
    redis:
      address: redis-master.redis.svc.cluster.local:6379
      username: default
      password: $(kubectl get secret redis -n redis -o jsonpath='{.data.redis-password}' | base64 -d)
    rtc:
      tcp_port: 7881
      udp_port: 7882
      port_range_start: 30000
      port_range_end: 30100
      use_external_ip: true
    turn:
      enabled: false
EOF
)"
kubectl -n whispr-preprod rollout restart deployment/livekit-server
```

Share the same `API_KEY` / `API_SECRET` pair with the calls-service via
its own env secret. Do **not** commit the real values.

> **Why not `storeKeysInSecret.existingSecret`?** Chart 1.7.x / 1.9.x
> mounts `livekit.key_file` at a subPath equal to the same absolute path
> (`/keys.yaml`), and kubelet rejects any subPath with a leading slash.
> Keeping the keys inline in the ConfigMap (via either `helm.parameters`
> or a manual patch) is the only path that works today.

### 2. Redis password (REQUIRED before first traffic)

Same flow as above: either add `livekit.redis.password` via
`helm.parameters` in the ArgoCD Application, or bake it into the manual
patch shown above.

The password is the `default` ACL password of the shared Bitnami Redis
cluster (namespace `redis`, secret `redis`, key `redis-password`).

### 3. DNS

`livekit-preprod.roadmvn.com` must resolve to the cluster ingress IP.
Already provisioned.

### 4. TURN (optional, currently OFF)

TURN is disabled in `helm-values.yaml`. Enabling it requires:
- DNS record for `turn-preprod.roadmvn.com` pointing to the node's public IP
- TLS cert in a secret referenced by `livekit.turn.secretName`

Switch `livekit.turn.enabled: true` and rerun the sync once the cert is
available.

## Post-deploy verification

```bash
kubectl -n whispr-preprod get pods -l app.kubernetes.io/name=livekit-server

# HTTP reachable via ingress
curl -v https://livekit-preprod.roadmvn.com/

# API endpoint (expect 401 without a signed token)
curl -v https://livekit-preprod.roadmvn.com/twirp/livekit.RoomService/ListRooms
```
