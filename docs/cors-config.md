# Configuration CORS

## Politique

Chaque service configure ses propres origines CORS autorisées via la variable `CORS_ORIGINS`.

```
Requête navigateur ──▶ Nginx Ingress ──▶ Service
                             │
                       Vérif Origin
                        ok │ ko
                       ┌───┼───┐
                       │       │
                   Passthrough  403
```
