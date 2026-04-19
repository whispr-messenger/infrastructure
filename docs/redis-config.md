# Configuration Redis

## Rôle

Redis est utilisé comme cache et broker de sessions pour les microservices.

## Services qui utilisent Redis

| Service | Usage |
|---------|-------|
| auth-service | Cache de tokens, rate limiting |
| messaging-service | Pub/Sub temps réel |
| user-service | Cache de profils |
| notification-service | Cache d'appareils |
| scheduling-service | Bull Queue (jobs) |
