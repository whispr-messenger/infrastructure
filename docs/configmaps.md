# ConfigMaps

## Usage

Les ConfigMaps stockent la configuration non sensible des services.

```
ConfigMap ──▶ Volume mount ──▶ Pod
     ou
ConfigMap ──▶ Env vars ──▶ Pod
```

Les données sensibles (mots de passe, clés) passent par Vault, pas les ConfigMaps.
