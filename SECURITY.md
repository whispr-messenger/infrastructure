# Sécurité Infrastructure

## Réseau

- mTLS entre tous les services via Istio
- TLS sur tout le trafic entrant via Cert-Manager
- Network policies pour isoler les namespaces

## Secrets

- Tous les secrets gérés via HashiCorp Vault
- Rotation possible sans redéploiement

## Accès

- RBAC Kubernetes pour contrôler les permissions
- Service accounts dédiés par service
