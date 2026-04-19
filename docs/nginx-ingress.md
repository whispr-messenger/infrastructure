# Nginx Ingress Controller

## Rôle

Le Nginx Ingress Controller expose les services au trafic externe et gère la terminaison TLS.

## Routing

```
whispr.fr/auth/*       ──▶ auth-service
whispr.fr/messaging/*  ──▶ messaging-service
whispr.fr/user/*       ──▶ user-service
whispr.fr/media/*      ──▶ media-service
whispr.fr/scheduling/* ──▶ scheduling-service
```
