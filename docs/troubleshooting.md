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

### Vérifier le statut ArgoCD

```bash
argocd app list
argocd app get <app-name>
```

### Vérifier Istio

```bash
istioctl analyze
kubectl get virtualservices -A
```

### Accéder à Vault

```bash
kubectl exec -it vault-0 -- vault status
```
