# Service Discovery

## DNS interne K8s

```
<service-name>.<namespace>.svc.cluster.local
```

Exemples :
- `auth-service.default.svc.cluster.local:3000`
- `redis.default.svc.cluster.local:6379`
- `postgresql.default.svc.cluster.local:5432`

Istio intercepte ces résolutions via les sidecars Envoy.
