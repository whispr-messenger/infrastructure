# livekit-server (devzeyu preprod)

SFU LiveKit minimal pour `calls-service` sur le cluster k3d local.

## Scope

- **Signalisation HTTP/WS** (port 7880) : accessible dans le cluster via
  `http://livekit-server.whispr-preprod:7880` (consomme par `calls-service`) et
  depuis Internet via Traefik sur `wss://whispr.devzeyu.com/livekit/`.
- **Media RTC** : **non fonctionnel de bout en bout** pour l'instant. Les
  noeuds k3d sont des containers Docker et les ports UDP 50000-50100 ne sont
  pas publies sur l'hote (exigerait de recreer le cluster avec
  `--port-add 50000-50100/udp`). En l'etat, `create_room` / signalisation /
  tokens fonctionnent, mais un client browser ne peut pas etablir le flux
  media cote reseau. A budgeter separement.

## Ressources

- `deployment.yaml` : Deployment `livekit-server` (replicas 1, strategy
  Recreate, image `livekit/livekit-server:v1.8.4`).
- `service.yaml` : Service ClusterIP (ports 7880 http/ws, 7881 rtc-tcp).
- `configmap.yaml` : `livekit-server-config` (port, redis, rtc sans TURN).
- Les cles d'API sont dans le Secret `livekit-keys` (cree hors-git) monte via
  env vars et ecrit dans `/tmp/keys.yaml` au demarrage.

## Bootstrap manuel (une seule fois)

### 1. Cles d'API

```bash
API_KEY="APIkey$(openssl rand -hex 6)"
API_SECRET=$(openssl rand -base64 40 | tr -d '/+=' | head -c 64)
kubectl -n whispr-preprod create secret generic livekit-keys \
  --from-literal=api-key="$API_KEY" \
  --from-literal=api-secret="$API_SECRET"
```

La meme paire doit ensuite etre injectee dans `calls-service-env` (cle
`LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET`) pour que le backend et le SFU
partagent le meme signing.

### 2. Redis

Pas d'action : reutilise le Bitnami Redis partage (`redis-master.redis.svc`),
pas d'auth en dev, pas de Sentinel.
