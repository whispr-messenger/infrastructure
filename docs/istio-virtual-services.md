# Istio VirtualServices

## Routing

Les VirtualServices définissent les règles de routing dans le mesh.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: auth-service
spec:
  hosts:
    - auth-service
  http:
    - route:
        - destination:
            host: auth-service
            port:
              number: 3000
```

## Vérifier les routes

```bash
kubectl get virtualservices -A
```
