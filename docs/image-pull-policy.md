# Image Pull Policy

## Configuration

| Environnement | Policy | Raison |
|---------------|--------|--------|
| Dev (k3d) | Always | Images locales changent souvent |
| Preprod | IfNotPresent | Réduire le temps de démarrage |
| Production | IfNotPresent | Stabilité |

Les images sont taggées par SHA de commit, donc `IfNotPresent` est sûr en prod.
