# Local Kubernetes Development with k3d and Tilt

This guide explains how to start and use the Whispr local Kubernetes development environment.

## Prerequisites

Install the following tools:

| Tool | Purpose | Install |
|------|---------|---------|
| [Docker](https://docs.docker.com/get-docker/) | Container runtime | Required by k3d |
| [k3d](https://k3d.io/#installation) | Lightweight k3s cluster in Docker | `brew install k3d` / `curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \| bash` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Kubernetes CLI | `brew install kubectl` |
| [Tilt](https://docs.tilt.dev/install.html) | Hot-reload orchestration | `curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh \| bash` |

## Quick Start

### 1. Bootstrap the cluster

Run the setup script once (idempotent — safe to re-run):

```bash
./scripts/dev-setup.sh
```

This creates:
- A k3d local registry at `localhost:5000`
- A k3d cluster named `whispr-dev` with port mappings:
  - `0.0.0.0:3001` → cluster HTTP ingress
  - `0.0.0.0:50051` → cluster gRPC ingress
- The `whispr-dev` namespace

### 2. Start all services

From the **root of this repository** (`infrastructure/`):

```bash
tilt up
```

Tilt opens a browser UI at `http://localhost:10350` where you can monitor all services.

To run without the browser UI:

```bash
tilt up --stream
```

### 3. Tear down

```bash
tilt down
```

To also delete the cluster and registry:

```bash
k3d cluster delete whispr-dev
k3d registry delete whispr-registry
```

---

## Architecture

```
whispr-dev namespace
├── postgres          (postgres:15-alpine)
├── redis             (redis:7-alpine)
├── auth-service      (NestJS, HTTP :3001, gRPC :50056, debug :9229)
├── user-service      (NestJS, HTTP :3002, gRPC :50055, debug :9229)
├── media-service     (NestJS, HTTP :3003, gRPC :50054, debug :9229)
├── scheduling-service (NestJS, HTTP :3004, gRPC :50052, debug :9229)
├── notification-service (Elixir/Phoenix, HTTP :4002, gRPC :4003)
└── messaging-service (Elixir/Phoenix, HTTP :4000, gRPC :50051)
```

Images are built locally and pushed to the k3d registry (`k3d-whispr-registry:5000`), not pulled from `ghcr.io`.

---

## Hot-Reload (NestJS services)

Tilt watches `src/` in each NestJS service directory. When a `.ts` file changes:

1. Tilt syncs the changed files into the running container.
2. Tilt runs `npm run build` inside the container.
3. The NestJS process picks up the rebuilt output.

No pod restart is needed for TypeScript changes.

Elixir/Phoenix services require a full image rebuild on code changes (triggered automatically by Tilt when it detects a file change in the service directory).

---

## Debugging NestJS Services

Each NestJS service exposes port `9229` for the Node.js inspector. To attach VS Code:

Add this to `.vscode/launch.json`:

```json
{
  "type": "node",
  "request": "attach",
  "name": "Attach to auth-service",
  "port": 9229,
  "restart": true,
  "localRoot": "${workspaceFolder}/../auth-service",
  "remoteRoot": "/app"
}
```

Adjust `port` and paths for each service.

---

## Manifests

Dev-specific Kubernetes manifests live under `k8s/whispr/development/`:

```
k8s/whispr/development/
├── namespace.yaml
├── postgres/
│   ├── configmap.yaml   (init SQL — creates one DB per service)
│   ├── secret.yaml      (POSTGRES_USER / POSTGRES_PASSWORD)
│   ├── deployment.yaml
│   └── service.yaml
├── redis/
│   ├── deployment.yaml
│   └── service.yaml
├── auth-service/
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── user-service/        (same structure)
├── media-service/       (same structure)
├── messaging-service/   (same structure)
├── notification-service/ (same structure)
└── scheduling-service/  (same structure)
```

Secrets in these manifests use **plaintext dev values** intentionally — they are not used in production. Production secrets are managed by Vault.

---

## Differences from Production

| Aspect | Dev (k3d + Tilt) | Production (GKE + ArgoCD) |
|--------|-----------------|--------------------------|
| Images | k3d local registry | `ghcr.io/whispr-messenger/...` |
| Secrets | Plaintext in `secret.yaml` | Vault dynamic secrets |
| Redis | Single node, direct mode | Sentinel cluster |
| Replicas | 1 per service | 1–2 per service |
| Security context | None (dev simplicity) | Non-root, read-only FS |
| Istio | Not installed | Service mesh enabled |

---

## Troubleshooting

**`k3d cluster create` fails — port already in use**

Check what is using port 3001:
```bash
lsof -i :3001
```

**Pod stuck in `ImagePullBackOff`**

Ensure your service image was built and pushed to the local registry:
```bash
docker pull k3d-whispr-registry:5000/auth-service:dev
```

Or trigger a rebuild in the Tilt UI.

**Postgres init script did not run**

The init script only runs on first cluster creation. Delete the cluster and re-run `dev-setup.sh`:
```bash
k3d cluster delete whispr-dev
./scripts/dev-setup.sh
```
