# Troubleshooting

## Commandes utiles

### Vérifier l'état des pods

```bash
kubectl get pods -A
```

### Logs d'un service

```bash
kubectl logs -f deployment/auth-service
```

### Redémarrer un déploiement

```bash
kubectl rollout restart deployment/auth-service
```
