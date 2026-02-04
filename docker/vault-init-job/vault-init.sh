#!/bin/sh
set -e

echo "=== Vault Initialization Script ==="
echo "Vault Address: $VAULT_ADDR"

# Wait for Vault to be reachable (accepts both 200 and 204 status codes)
# We use query params to ensure Vault returns 204 even if sealed or uninitialized
echo "Waiting for Vault to be ready..."
until curl -s -f -o /dev/null "http://vault.vault.svc:8200/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"; do
  echo "Vault not ready (status code implies not reachable or error), waiting..."
  sleep 5
done
echo "✓ Vault is reachable"

# Check if Vault is already initialized
echo "Checking Vault initialization status..."
if vault status | grep -q "Initialized.*true"; then
  echo "✓ Vault is already initialized"

  # Check if unseal keys Secret exists
  if kubectl get secret vault-init-keys -n vault >/dev/null 2>&1; then
    echo "✓ Unseal keys Secret exists, attempting to unseal..."

    # Extract unseal keys from Secret
    UNSEAL_KEY_1=$(kubectl get secret vault-init-keys -n vault -o jsonpath='{.data.unseal-key-1}' | base64 -d)
    UNSEAL_KEY_2=$(kubectl get secret vault-init-keys -n vault -o jsonpath='{.data.unseal-key-2}' | base64 -d)
    UNSEAL_KEY_3=$(kubectl get secret vault-init-keys -n vault -o jsonpath='{.data.unseal-key-3}' | base64 -d)

    # Unseal Vault (ignore errors if already unsealed)
    vault operator unseal "$UNSEAL_KEY_1" || true
    vault operator unseal "$UNSEAL_KEY_2" || true
    vault operator unseal "$UNSEAL_KEY_3" || true

    echo "✓ Vault unsealed successfully"
  else
    echo "⚠ WARNING: Vault is initialized but Secret not found. Manual intervention required."
    exit 1
  fi
else
  echo "Initializing Vault..."

  # Initialize Vault with 5 key shares and 3 key threshold
  vault operator init -key-shares=5 -key-threshold=3 -format=json > /tmp/vault-init.json

  # Extract keys and root token using yq (raw output)
  UNSEAL_KEY_1=$(yq '.unseal_keys_b64[0]' /tmp/vault-init.json)
  UNSEAL_KEY_2=$(yq '.unseal_keys_b64[1]' /tmp/vault-init.json)
  UNSEAL_KEY_3=$(yq '.unseal_keys_b64[2]' /tmp/vault-init.json)
  UNSEAL_KEY_4=$(yq '.unseal_keys_b64[3]' /tmp/vault-init.json)
  UNSEAL_KEY_5=$(yq '.unseal_keys_b64[4]' /tmp/vault-init.json)
  ROOT_TOKEN=$(yq '.root_token' /tmp/vault-init.json)

  # Create Kubernetes Secret with init data
  kubectl create secret generic vault-init-keys \
    --from-literal=unseal-key-1="$UNSEAL_KEY_1" \
    --from-literal=unseal-key-2="$UNSEAL_KEY_2" \
    --from-literal=unseal-key-3="$UNSEAL_KEY_3" \
    --from-literal=unseal-key-4="$UNSEAL_KEY_4" \
    --from-literal=unseal-key-5="$UNSEAL_KEY_5" \
    --from-literal=root-token="$ROOT_TOKEN" \
    --namespace=vault

  echo "✓ Vault initialized and keys stored in Secret"

  # Unseal Vault
  vault operator unseal "$UNSEAL_KEY_1"
  vault operator unseal "$UNSEAL_KEY_2"
  vault operator unseal "$UNSEAL_KEY_3"

  echo "✓ Vault unsealed successfully"

  # Clean up sensitive file
  rm -f /tmp/vault-init.json
fi

echo "=== Vault initialization complete ==="
