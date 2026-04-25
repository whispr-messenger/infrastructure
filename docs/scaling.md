# Scaling

## Horizontal Pod Autoscaler

Les microservices utilisent le HPA pour scaler automatiquement en fonction de la charge.

## Vertical Pod Autoscaler

Le VPA ajuste les requests/limits CPU et mémoire des pods.

## Schéma

```
Charge élevée ──▶ HPA détecte ──▶ Scale up pods
                                        │
Charge faible ──▶ HPA détecte ──▶ Scale down pods
```

## Commandes utiles

```bash
# Voir le HPA
kubectl get hpa

# Voir le VPA
kubectl get vpa
```
