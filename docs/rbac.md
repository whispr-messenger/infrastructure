# RBAC - Role Based Access Control

## Configuration

Les permissions Kubernetes sont gérées via RBAC dans `k8s/rbac/`.

## Rôles

| Rôle | Accès |
|------|-------|
| platform-admin | Full access au cluster |
| service-account | Accès limité au namespace du service |
