# Kubectl Cheatsheet

## Commandes fréquentes

```bash
# Voir tous les pods
kubectl get pods -A

# Logs d'un pod
kubectl logs -f <pod-name>

# Exec dans un pod
kubectl exec -it <pod-name> -- /bin/sh

# Describe un pod (debug)
kubectl describe pod <pod-name>

# Port-forward (accès local)
kubectl port-forward svc/grafana 3000:3000

# Voir les events récents
kubectl get events --sort-by='.lastTimestamp'
```
