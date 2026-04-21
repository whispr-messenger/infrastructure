# Tiltfile

## Développement local

Le Tiltfile à la racine configure le hot-reload local avec k3d.

```
Tilt watch ──▶ Changement détecté ──▶ Build image ──▶ Deploy dans k3d
                                                          │
                                                    Hot reload
                                                    automatique
```

## Services gérés

Le Tiltfile démarre tous les microservices en mode dev avec leurs dépendances (PostgreSQL, Redis).
