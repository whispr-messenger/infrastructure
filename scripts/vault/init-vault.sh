#!/bin/bash
set -e

echo "========================================="
echo "HashiCorp Vault Initialization Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is configured
if ! kubectl get pods -n vault &>/dev/null; then
    echo -e "${RED}Error: kubectl is not configured or vault namespace doesn't exist${NC}"
    exit 1
fi

# Wait for Vault pods to be ready
echo "Waiting for Vault pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

# Check if Vault is already initialized
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
INIT_STATUS=$(kubectl exec -n vault $VAULT_POD -- vault status -format=json 2>/dev/null | jq -r '.initialized' || echo "false")

if [ "$INIT_STATUS" == "true" ]; then
    echo -e "${YELLOW}Vault is already initialized${NC}"
    echo "If you need to unseal Vault, use the unseal keys you saved during initialization"
    exit 0
fi

echo ""
echo "Initializing Vault..."
echo ""

# Initialize Vault
INIT_OUTPUT=$(kubectl exec -n vault $VAULT_POD -- vault operator init -key-shares=5 -key-threshold=3 -format=json)

# Extract unseal keys and root token
UNSEAL_KEY_1=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[0]')
UNSEAL_KEY_2=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[1]')
UNSEAL_KEY_3=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[2]')
UNSEAL_KEY_4=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[3]')
UNSEAL_KEY_5=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[4]')
ROOT_TOKEN=$(echo $INIT_OUTPUT | jq -r '.root_token')

echo -e "${GREEN}Vault initialized successfully!${NC}"
echo ""
echo -e "${RED}=========================================${NC}"
echo -e "${RED}IMPORTANT: Save these keys securely!${NC}"
echo -e "${RED}=========================================${NC}"
echo ""
echo "Unseal Key 1: $UNSEAL_KEY_1"
echo "Unseal Key 2: $UNSEAL_KEY_2"
echo "Unseal Key 3: $UNSEAL_KEY_3"
echo "Unseal Key 4: $UNSEAL_KEY_4"
echo "Unseal Key 5: $UNSEAL_KEY_5"
echo ""
echo "Root Token: $ROOT_TOKEN"
echo ""
echo -e "${RED}=========================================${NC}"
echo -e "${RED}Store these keys in a secure location!${NC}"
echo -e "${RED}Recommended: Google Secret Manager or 1Password${NC}"
echo -e "${RED}=========================================${NC}"
echo ""

# Unseal Vault on all pods
echo "Unsealing Vault pods..."
for pod in $(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].metadata.name}'); do
    echo "Unsealing $pod..."
    kubectl exec -n vault $pod -- vault operator unseal $UNSEAL_KEY_1 >/dev/null
    kubectl exec -n vault $pod -- vault operator unseal $UNSEAL_KEY_2 >/dev/null
    kubectl exec -n vault $pod -- vault operator unseal $UNSEAL_KEY_3 >/dev/null
done

echo -e "${GREEN}All Vault pods unsealed successfully!${NC}"
echo ""

# Login to Vault
echo "Logging in to Vault..."
kubectl exec -n vault $VAULT_POD -- vault login $ROOT_TOKEN >/dev/null

# Enable Kubernetes auth
echo "Enabling Kubernetes authentication..."
kubectl exec -n vault $VAULT_POD -- vault auth enable kubernetes >/dev/null 2>&1 || echo "Kubernetes auth already enabled"

# Configure Kubernetes auth
echo "Configuring Kubernetes authentication..."
kubectl exec -n vault $VAULT_POD -- vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc:443" >/dev/null

# Enable KV v2 secrets engine
echo "Enabling KV v2 secrets engine..."
kubectl exec -n vault $VAULT_POD -- vault secrets enable -path=secret kv-v2 >/dev/null 2>&1 || echo "KV v2 already enabled"

# Create policy for external-secrets
echo "Creating policy for External Secrets Operator..."
kubectl exec -n vault $VAULT_POD -- vault policy write external-secrets - <<EOF
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOF

# Create role for external-secrets
echo "Creating role for External Secrets Operator..."
kubectl exec -n vault $VAULT_POD -- vault write auth/kubernetes/role/external-secrets \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets-system \
    policies=external-secrets \
    ttl=24h >/dev/null

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Vault initialization complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Save the unseal keys and root token securely"
echo "2. Run ./populate-secrets.sh to add secrets to Vault"
echo "3. Deploy the ClusterSecretStore: kubectl apply -f argocd/k8s/vault/vault-secret-store.yaml"
echo ""
