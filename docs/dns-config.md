# Configuration DNS

## Domaine principal

Le domaine `whispr.fr` pointe vers le load balancer GCP du cluster.

## Sous-domaines

| Sous-domaine | Cible |
|-------------|-------|
| whispr.fr | Application principale |
| argocd.whispr.epitech.beer | ArgoCD UI |
| sonarqube.whispr.epitech.beer | SonarQube |

## Flux DNS

```
Client ──▶ whispr.fr ──▶ Cloud DNS ──▶ GCP LB ──▶ Nginx Ingress
```

## Propagation DNS

```
Changement DNS ──▶ Cloud DNS ──▶ Propagation (~5min)
                                       │
                                 Vérification
                                 dig whispr.fr
```
