# Setup k3d

## Installation

```bash
brew install k3d
```

## Créer le cluster

```bash
k3d cluster create whispr
```

## Vérifier

```bash
kubectl cluster-info
```

## Configuration réseau

```
┌─────────────┐     ┌─────────────┐
│   Docker     │────▶│  k3d cluster│
│   Network    │     │  (K3s)      │
└─────────────┘     └──────┬──────┘
                           │
                     Port mapping
                     localhost:8080
```
