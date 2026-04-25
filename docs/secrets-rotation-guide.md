# Guide de rotation des secrets

## Étapes

1. Se connecter à Vault

```bash
kubectl exec -it vault-0 -- vault login
```

2. Mettre à jour le secret

```bash
vault kv put secret/<service> KEY=new_value
```

3. ESO synchronise automatiquement (polling ~30s)

4. Restart les pods si nécessaire

```bash
kubectl rollout restart deployment/<service>
```
