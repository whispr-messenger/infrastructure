#!/usr/bin/env bash
# dev-setup.sh — bootstrap a local k3d cluster for Whispr development.
#
# Creates a k3d cluster named "whispr-dev" with:
#   - A local image registry at localhost:5000
#   - HTTP port mapping  0.0.0.0:3001 → cluster ingress
#   - gRPC port mapping  0.0.0.0:50051 → cluster ingress
#
# Prerequisites: k3d, kubectl, tilt

set -euo pipefail

CLUSTER_NAME="whispr-dev"
REGISTRY_NAME="whispr-registry"
REGISTRY_PORT="5000"
HTTP_PORT="3001"
GRPC_PORT="50051"

# ---------------------------------------------------------------------------
# 1. Create local registry (idempotent)
# ---------------------------------------------------------------------------
if k3d registry list 2>/dev/null | grep -q "${REGISTRY_NAME}"; then
  echo "[registry] ${REGISTRY_NAME} already exists — skipping"
else
  echo "[registry] Creating local registry ${REGISTRY_NAME}:${REGISTRY_PORT}"
  k3d registry create "${REGISTRY_NAME}" --port "${REGISTRY_PORT}"
fi

# ---------------------------------------------------------------------------
# 2. Create cluster (idempotent)
# ---------------------------------------------------------------------------
if k3d cluster list 2>/dev/null | grep -q "${CLUSTER_NAME}"; then
  echo "[cluster] ${CLUSTER_NAME} already exists — skipping"
else
  echo "[cluster] Creating k3d cluster ${CLUSTER_NAME}"
  k3d cluster create "${CLUSTER_NAME}" \
    --registry-use "k3d-${REGISTRY_NAME}:${REGISTRY_PORT}" \
    --port "${HTTP_PORT}:80@loadbalancer" \
    --port "${GRPC_PORT}:50051@loadbalancer" \
    --agents 1 \
    --wait \
    --k3s-arg "--kubelet-arg=image-pull-progress-deadline=60s@agent:*"

  # Patch containerd hosts.toml on all nodes so the local registry is
  # accessed over plain HTTP (k3d generates an HTTPS server line by default).
  echo "[registry] Configuring HTTP access for k3d-${REGISTRY_NAME}:${REGISTRY_PORT}"
  HOSTS_TOML="server = \"http://k3d-${REGISTRY_NAME}:${REGISTRY_PORT}\"

[host.\"http://k3d-${REGISTRY_NAME}:${REGISTRY_PORT}\"]
  capabilities = [\"pull\", \"resolve\", \"push\"]"

  for node in $(k3d node list --cluster "${CLUSTER_NAME}" -o json 2>/dev/null | python3 -c "import sys,json; [print(n['name']) for n in json.load(sys.stdin) if n['role'] in ('server','agent')]"); do
    docker exec "${node}" sh -c "mkdir -p \"/var/lib/rancher/k3s/agent/etc/containerd/certs.d/k3d-${REGISTRY_NAME}:${REGISTRY_PORT}\" && cat > \"/var/lib/rancher/k3s/agent/etc/containerd/certs.d/k3d-${REGISTRY_NAME}:${REGISTRY_PORT}/hosts.toml\" <<'TOML'
${HOSTS_TOML}
TOML"
    echo "[registry]   patched ${node}"
  done

  # Restart nodes to reload containerd config
  echo "[cluster] Restarting nodes to apply registry config..."
  k3d node list --cluster "${CLUSTER_NAME}" -o json 2>/dev/null \
    | python3 -c "import sys,json; [print(n['name']) for n in json.load(sys.stdin) if n['role'] in ('server','agent')]" \
    | xargs docker restart
  kubectl wait --for=condition=Ready node --all --timeout=120s
fi

# ---------------------------------------------------------------------------
# 3. Switch kubectl context
# ---------------------------------------------------------------------------
kubectl config use-context "k3d-${CLUSTER_NAME}"

# ---------------------------------------------------------------------------
# 4. Create dev namespace
# ---------------------------------------------------------------------------
kubectl get namespace whispr-dev &>/dev/null || kubectl create namespace whispr-dev

# ---------------------------------------------------------------------------
# 5. Done
# ---------------------------------------------------------------------------
echo ""
echo "[done] Cluster ready. Run 'tilt up' from the repo root to start services."
echo "       Registry: localhost:${REGISTRY_PORT}"
echo "       kubectl context: k3d-${CLUSTER_NAME}"
