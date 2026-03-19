#!/usr/bin/env bash
# dev-setup.sh — bootstrap a local k3d cluster for Whispr development.
#
# Creates a k3d cluster named "whispr-dev" with:
#   - A local image registry at localhost:5000
#   - HTTP port mapping  0.0.0.0:3001 → cluster ingress
#
# Prerequisites: k3d, kubectl, tilt

set -euo pipefail

CLUSTER_NAME="whispr-dev"
REGISTRY_NAME="whispr-dev-registry"
REGISTRY_PORT="5000"
HTTP_PORT="8080"

function print_header() {
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

# ---------------------------------------------------------------------------
# 1. Create local registry (idempotent)
# ---------------------------------------------------------------------------
if k3d registry list 2>/dev/null | grep -q "${REGISTRY_NAME}"; then
  print_header "[registry] ${REGISTRY_NAME} already exists — skipping"
else
  echo "[registry] Creating local registry ${REGISTRY_NAME}:${REGISTRY_PORT}"
  k3d registry create "${REGISTRY_NAME}" --port "${REGISTRY_PORT}"
fi

# ---------------------------------------------------------------------------
# 2. Create cluster (idempotent)
# ---------------------------------------------------------------------------
if k3d cluster list 2>/dev/null | grep -q "${CLUSTER_NAME}"; then
  print_header "[cluster] ${CLUSTER_NAME} already exists — skipping"
else
  print_header "[cluster] Creating k3d cluster ${CLUSTER_NAME}"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

  k3d cluster create "${CLUSTER_NAME}" \
    --registry-use "k3d-${REGISTRY_NAME}:${REGISTRY_PORT}" \
    --registry-config "${REPO_ROOT}/k3d/registries.yaml" \
    --port "${HTTP_PORT}:80@loadbalancer" \
    --agents 2 \
    --wait \
    --timeout 120s

  print_header "[cluster] Waiting for nodes to become ready..."
  kubectl wait --for=condition=Ready node --all --timeout=120s
fi

# ---------------------------------------------------------------------------
# 3. Increase inotify limits on k3d nodes (needed for NestJS dev file watchers)
# ---------------------------------------------------------------------------
print_header "[sysctl] Increasing inotify watches on k3d nodes"
for node in $(docker ps --filter "name=k3d-${CLUSTER_NAME}" --format '{{.Names}}'); do
  docker exec "${node}" sysctl -w fs.inotify.max_user_watches=524288 >/dev/null
  docker exec "${node}" sysctl -w fs.inotify.max_user_instances=512 >/dev/null
  echo "  ✓ ${node}"
done

# ---------------------------------------------------------------------------
# 4. Merge kubeconfig and switch context
# ---------------------------------------------------------------------------
k3d kubeconfig merge "${CLUSTER_NAME}" --kubeconfig-merge-default --kubeconfig-switch-context

if [  $(kubectl config current-context) != "k3d-${CLUSTER_NAME}" ]; then
  print_header "[kubeconfig] Switching kubectl context to k3d-${CLUSTER_NAME}"
  kubectl config use-context "k3d-${CLUSTER_NAME}"
else
  print_header "[kubeconfig] kubectl context already set to k3d-${CLUSTER_NAME} - skipping"
fi

# ---------------------------------------------------------------------------
# 5. Create dev namespace
# ---------------------------------------------------------------------------
kubectl get namespace whispr-dev &>/dev/null || kubectl create namespace whispr-dev

# ---------------------------------------------------------------------------
# 6. Done
# ---------------------------------------------------------------------------
echo ""
print_header "[done] Cluster ready."
echo ""
echo "Run 'tilt up' from the repo root to start services."
echo " - Registry: localhost:${REGISTRY_PORT}"
echo " - kubectl context: k3d-${CLUSTER_NAME}"
