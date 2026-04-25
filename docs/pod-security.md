# Sécurité des pods

## Bonnes pratiques appliquées

- Containers non-root
- readOnlyRootFilesystem activé
- Pas de privilege escalation
- Resources limits définis

```
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```
