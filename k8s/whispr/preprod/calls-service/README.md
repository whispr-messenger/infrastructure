# calls-service (devzeyu preprod)

Déploiement Elixir/Phoenix de `whispr-messenger/calls-service` sur le cluster
k3d local (`whispr.devzeyu.com`).

## Ressources

- `deployment.yaml` : Deployment (replicas 1, image k3d registry local)
- `service.yaml` : Service NodePort (http 30122, gRPC 31412)
- `configmap.yaml` : `calls-service-config` (hôtes, URLs publiques, placeholders LiveKit)

## Secret hors-git `calls-service-env`

À créer une seule fois, hors du repo :

```bash
SECRET_KEY_BASE=$(openssl rand -base64 48 | tr -d '=+/' | cut -c1-64)
kubectl -n whispr-preprod create secret generic calls-service-env \
  --from-literal=DATABASE_URL="ecto://postgres:<pg-password>@postgresql.postgresql.svc.cluster.local:5432/whispr_calls" \
  --from-literal=SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  --from-literal=LIVEKIT_API_KEY="devkey" \
  --from-literal=LIVEKIT_API_SECRET="devsecret"
```

La DB `whispr_calls` doit être créée avant le premier démarrage :

```bash
kubectl -n postgresql exec postgresql-0 -- \
  psql -U postgres -c "CREATE DATABASE whispr_calls;"
```

Les migrations Ecto sont exécutées par l'entrypoint du container avant le
démarrage de Phoenix (`WhisprCalls.Release.migrate()`).

## Image

Tant que la CI `whispr-messenger/calls-service` n'a pas publié de tag `sha-*`
sur ghcr.io, l'image est buildée localement et poussée sur le registry k3d :

```bash
cd /home/pc/whispr/calls-service
docker buildx build -f docker/prod/Dockerfile \
  -t localhost:5000/calls-service:dev --load .
docker push localhost:5000/calls-service:dev
```

## Routage

Le path `/calls` du vhost `whispr.devzeyu.com` est mappé vers ce service par
l'IngressRoute Traefik `whispr-api` de `k8s/whispr/devzeyu/ingress/`.
