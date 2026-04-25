# GitGuardian

## Rôle

GitGuardian scanne chaque PR pour détecter des secrets (clés API, mots de passe, tokens) dans le code.

## Intégration

Le scan est automatique sur chaque push. Si un secret est détecté, la PR est bloquée.
