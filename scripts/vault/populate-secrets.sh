#!/bin/bash
set -e

echo "========================================="
echo "Populating Vault with Secrets"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get Vault pod
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

# Check if logged in (will fail if not)
if ! kubectl exec -n vault $VAULT_POD -- vault token lookup &>/dev/null; then
    echo -e "${YELLOW}Please login to Vault first:${NC}"
    echo "kubectl exec -n vault $VAULT_POD -- vault login <ROOT_TOKEN>"
    exit 1
fi

echo "Adding secrets to Vault..."
echo ""

# PostgreSQL secrets
echo "Creating PostgreSQL secrets..."
POSTGRES_PASSWORD=$(openssl rand -base64 32)
kubectl exec -n vault $VAULT_POD -- vault kv put secret/postgresql \
    password="$POSTGRES_PASSWORD" \
    username="whispr" \
    database="whispr"

echo -e "${GREEN}✓ PostgreSQL secrets created${NC}"

# Redis secrets
echo "Creating Redis secrets..."
REDIS_PASSWORD=$(openssl rand -base64 32)
kubectl exec -n vault $VAULT_POD -- vault kv put secret/redis \
    password="$REDIS_PASSWORD"

echo -e "${GREEN}✓ Redis secrets created${NC}"

# MinIO secrets
echo "Creating MinIO secrets..."
MINIO_ROOT_USER="minioadmin"
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)
kubectl exec -n vault $VAULT_POD -- vault kv put secret/minio \
    rootUser="$MINIO_ROOT_USER" \
    rootPassword="$MINIO_ROOT_PASSWORD"

echo -e "${GREEN}✓ MinIO secrets created${NC}"

# Messaging Service secrets
echo "Creating Messaging Service secrets..."
MESSAGING_SECRET_KEY=$(openssl rand -base64 64)
kubectl exec -n vault $VAULT_POD -- vault kv put secret/messaging-service \
    DATABASE_URL="postgresql://whispr:$POSTGRES_PASSWORD@postgresql.whispr-prod.svc.cluster.local:5432/whispr_messaging" \
    REDIS_URL="redis://:$REDIS_PASSWORD@redis-master.whispr-prod.svc.cluster.local:6379/0" \
    SECRET_KEY_BASE="$MESSAGING_SECRET_KEY"

echo -e "${GREEN}✓ Messaging Service secrets created${NC}"

# Scheduling Service secrets
echo "Creating Scheduling Service secrets..."
kubectl exec -n vault $VAULT_POD -- vault kv put secret/scheduling-service \
    DATABASE_URL="postgresql://whispr:$POSTGRES_PASSWORD@postgresql.whispr-prod.svc.cluster.local:5432/whispr_scheduling" \
    REDIS_URL="redis://:$REDIS_PASSWORD@redis-master.whispr-prod.svc.cluster.local:6379/1"

echo -e "${GREEN}✓ Scheduling Service secrets created${NC}"

# Auth Service secrets (if needed)
echo "Creating Auth Service secrets..."
AUTH_SECRET_KEY=$(openssl rand -base64 64)
JWT_SECRET=$(openssl rand -base64 64)
kubectl exec -n vault $VAULT_POD -- vault kv put secret/auth-service \
    DATABASE_URL="postgresql://whispr:$POSTGRES_PASSWORD@postgresql.whispr-prod.svc.cluster.local:5432/whispr_auth" \
    REDIS_URL="redis://:$REDIS_PASSWORD@redis-master.whispr-prod.svc.cluster.local:6379/2" \
    SECRET_KEY_BASE="$AUTH_SECRET_KEY" \
    JWT_SECRET="$JWT_SECRET"

echo -e "${GREEN}✓ Auth Service secrets created${NC}"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}All secrets populated successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Secrets created:"
echo "  - secret/postgresql"
echo "  - secret/redis"
echo "  - secret/minio"
echo "  - secret/messaging-service"
echo "  - secret/scheduling-service"
echo "  - secret/auth-service"
echo ""
echo "Next steps:"
echo "1. Update your service manifests to use ExternalSecrets"
echo "2. Deploy the updated manifests via ArgoCD"
echo ""
