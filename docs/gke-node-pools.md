# Node Pools GKE

## Configuration

Le cluster utilise des node pools managés par GKE.

## Spécifications

| Pool | Machine type | Min | Max |
|------|-------------|-----|-----|
| default | e2-medium | 1 | 3 |

## Autoscaling

Le cluster autoscale en fonction de la demande en pods. GKE ajoute ou retire des nœuds automatiquement.
