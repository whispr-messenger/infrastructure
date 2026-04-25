# Standards de logging

## Format

Tous les services utilisent des logs structurés en JSON.

```json
{
  "timestamp": "2026-04-25T10:30:00Z",
  "level": "info",
  "service": "auth-service",
  "message": "Token refreshed",
  "userId": "user-123",
  "correlationId": "req-456"
}
```

## Niveaux

| Niveau | Usage |
|--------|-------|
| error | Erreurs non récupérables |
| warn | Situations anormales |
| info | Événements métier |
| debug | Détails techniques (dev only) |
