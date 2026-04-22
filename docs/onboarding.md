# Onboarding développeur

## Étapes

1. Recevoir les accès GCP (`platform-engineers-key.json`)
2. Configurer kubectl (voir `scripts/platform-engineers/`)
3. Installer les outils : `kubectl`, `terraform`, `just`, `k3d`
4. Cloner le repo infrastructure
5. Lancer le cluster local avec `k3d`

## Vérification

```bash
kubectl get nodes
kubectl get pods -A
```

Si tout est vert, l'environnement est prêt.
