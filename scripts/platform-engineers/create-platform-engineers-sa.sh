#!/bin/bash

# Script pour créer un service account générique pour les ingénieurs plateforme
# Usage: ./create-platform-engineers-sa.sh

set -e

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=$(gcloud config get-value project)
SA_NAME="platform-engineers"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="platform-engineers-key.json"
CLUSTER_NAME="whispr-messenger"
CLUSTER_ZONE="europe-west1-b"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Creating platform engineers service account on project $PROJECT_ID"

# 1. Créer le service account
log_info "Creating service account..."

gcloud iam service-accounts create $SA_NAME \
    --display-name="Platform Engineers" \
    --description="Shared service account for platform engineering team - GKE access, monitoring, debugging"

# 2. Donner les permissions IAM pour GKE
log_info "Adding GKE permissions..."

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.clusterViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.developer"

# 3. Permissions pour monitoring et debugging
log_info "Adding monitoring and logging permissions..."

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/logging.viewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/monitoring.viewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/monitoring.metricWriter"

# 4. Permissions pour Cloud Storage (backup, artifacts)
log_info "Adding storage permissions..."

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.objectViewer"

# 5. Permissions pour debugging avancé (optionnel)
log_info "Adding debugging permissions..."

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/clouddebugger.agent"

# 6. Créer une clé JSON
log_info "Creating JSON key..."

gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SA_EMAIL

# 7. Instructions d'utilisation
cat << EOF

${GREEN}Platform Engineers service account created successfully!${NC}

${YELLOW}Service Account Details:${NC}
- Name: $SA_NAME
- Email: $SA_EMAIL
- Key File: $KEY_FILE

${YELLOW}🔐 Permissions granted:${NC}
- GKE cluster viewer and developer access
- Logging and monitoring (read/write)
- Cloud Storage read access
- Debugging and tracing capabilities

${YELLOW}Usage Instructions for Engineers:${NC}

1. Securely share the key file: ${GREEN}$KEY_FILE${NC}

2. Each engineer should:
   ${GREEN}# Authenticate with the service account
   gcloud auth activate-service-account --key-file=$KEY_FILE
   
   # Set the project
   gcloud config set project $PROJECT_ID
   
   # Get cluster credentials
   gcloud container clusters get-credentials whispr-cluster --zone europe-west1-b
   
   # Test access
   kubectl get nodes
   kubectl get namespaces${NC}

${YELLOW}Key Rotation (recommended every 90 days):${NC}
   ${GREEN}# Create new key
   gcloud iam service-accounts keys create new-platform-engineers-key.json --iam-account=$SA_EMAIL
   
   # Delete old key (after everyone has updated)
   gcloud iam service-accounts keys delete KEY_ID --iam-account=$SA_EMAIL${NC}

${YELLOW}To revoke access later:${NC}
   ${GREEN}gcloud iam service-accounts delete $SA_EMAIL${NC}

${YELLOW}📝 Team Management:${NC}
- Share this key securely with: David, Gabriel, and other platform engineers
- Store the key in your password manager or secure storage
- Document who has access for audit purposes
- Rotate keys regularly for security

${YELLOW}🔒 Security Best Practices:${NC}
- Don't commit the key file to git
- Use secure channels to share the key
- Each engineer should store it securely locally
- Monitor usage in Cloud Console IAM logs
- Rotate keys if any engineer leaves the team

EOF

# 8. Sécuriser le fichier et l'ajouter au gitignore
chmod 600 $KEY_FILE

# Ajouter au gitignore s'il n'y est pas déjà
if ! grep -q "platform-engineers-key.json" ../.gitignore 2>/dev/null; then
    echo "platform-engineers-key.json" >> ../.gitignore
    log_info "Added key file to .gitignore"
fi

log_info "Platform Engineers service account ready!"
log_warn "🔐 Secure the key file and share it with your team through secure channels"