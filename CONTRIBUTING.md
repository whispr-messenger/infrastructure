# Contribuer à l'infrastructure

## Prérequis

- `kubectl` configuré sur le cluster
- `terraform` installé
- `just` (task runner)
- Accès GCP (voir README)

## Workflow

1. Créer une branche `WHISPR-XXX-description`
2. Modifier les manifests / terraform
3. Valider avec `kubectl apply --dry-run=client` ou `terraform plan`
4. Commiter et push
5. Ouvrir une PR vers `main`

## Conventions de commit

- `feat(k8s):` pour les nouvelles ressources
- `fix(helm):` pour les corrections
- `docs:` pour la documentation
- `chore(deploy):` pour les mises à jour d'images
