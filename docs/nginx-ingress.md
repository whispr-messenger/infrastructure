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

## TLS

Les certificats sont fournis automatiquement par Cert-Manager via Let's Encrypt.

## Schéma de routing complet

```
whispr.fr
  │
  ├── /auth/*        ──▶ auth-service:3000
  ├── /messaging/*   ──▶ messaging-service:4000
  ├── /user/*        ──▶ user-service:3000
  ├── /media/*       ──▶ media-service:3000
  ├── /scheduling/*  ──▶ scheduling-service:3000
  ├── /notification/*──▶ notification-service:4000
  └── /moderation/*  ──▶ moderation-service:8000
```
