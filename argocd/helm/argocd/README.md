# ArgoCD Helm Configuration

This directory contains the Helm values configuration for ArgoCD.

## Current Status

ArgoCD is currently installed via Helm but not self-managed through GitOps.
This configuration adds Redis HA persistence to prevent data loss and failover issues.

## Problem Being Solved

ArgoCD Redis HA was deployed without persistent storage (using emptyDir volumes).
This causes:
- Data loss on pod restarts
- Failed failover attempts with "no-good-slave" errors
- OAuth session loss
- Cluster split-brain scenarios

## Solution

Enable Redis HA persistence with PersistentVolumeClaims (8Gi standard-rwo).

## How to Apply

### Manual Update (Current Method)

```bash
cd infrastructure/argocd/infrastructure/argocd

# Upgrade ArgoCD with new values
helm upgrade argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm \
  --version 8.5.2 \
  --namespace argocd \
  --values values.yaml

# Wait for Redis pods to be recreated with PVCs
kubectl rollout status statefulset/argocd-redis-ha-server -n argocd

# Verify PVCs were created
kubectl get pvc -n argocd
```

### Expected Result

- 3 PVCs created: data-argocd-redis-ha-server-0, data-argocd-redis-ha-server-1, data-argocd-redis-ha-server-2
- Redis HA cluster with persistent storage
- No more data loss on pod restarts
- Proper failover behavior

## Future: GitOps Self-Management

To make ArgoCD fully self-managed through GitOps, we need to:
1. Create an ArgoCD Application that manages itself
2. Handle the bootstrap problem carefully
3. Ensure no disruption during the transition

This will be addressed in a future ticket.

## Related

- Jira: WHISPR-136
- Helm Chart: argo-cd v8.5.2
- Documentation: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
