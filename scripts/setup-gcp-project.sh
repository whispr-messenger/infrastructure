#!/bin/bash

set -e

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables
PROJECT_ID=""
SA_NAME="terraform-service-account"
SA_EMAIL=""
KEY_FILE="terraform-sa-key.json"

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

# Validation functions
validate_arguments() {
    if [ $# -eq 0 ]; then
        log_error "Usage: $0 <PROJECT_ID>"
        exit 1
    fi

    PROJECT_ID=$1
    SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

    log_info "Setting up GCP for project: $PROJECT_ID"
}

check_gcloud_installation() {
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Install it from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

authenticate_gcp() {
    log_info "Checking GCP authentication..."
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null; then
        log_warn "No active session found. Logging into GCP..."
        gcloud auth login
    fi
}

configure_project() {
    log_info "Configuring default project..."
    gcloud config set project $PROJECT_ID

    # Verify project exists
    if ! gcloud projects describe $PROJECT_ID > /dev/null 2>&1; then
        log_error "Project $PROJECT_ID does not exist or you don't have access to it"
        exit 1
    fi
}

# API management functions
enable_required_apis() {
    log_info "Enabling Google Cloud APIs..."
    local apis=(
        "container.googleapis.com"
        "compute.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "iam.googleapis.com"
        "servicenetworking.googleapis.com"
        "containerregistry.googleapis.com"
        "monitoring.googleapis.com"
        "logging.googleapis.com"
    )

    for api in "${apis[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable $api
    done
}

# Service Account management functions
create_service_account() {
    log_info "Creating Terraform service account..."
    if gcloud iam service-accounts describe $SA_EMAIL > /dev/null 2>&1; then
        log_warn "Service account $SA_EMAIL already exists"
    else
        gcloud iam service-accounts create $SA_NAME \
            --display-name="Terraform GKE Service Account" \
            --description="Service account for Terraform to manage GKE resources"
    fi
}

assign_service_account_roles() {
    log_info "Assigning roles to service account..."
    local roles=(
        "roles/container.admin"
        "roles/compute.admin"
        "roles/iam.serviceAccountUser"
        "roles/iam.serviceAccountAdmin"
        "roles/iam.securityAdmin"
        "roles/resourcemanager.projectIamAdmin"
        "roles/storage.admin"
        "roles/servicenetworking.networksAdmin"
    )

    for role in "${roles[@]}"; do
        log_info "Assigning role $role..."
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SA_EMAIL" \
            --role="$role" > /dev/null
    done
}

# Key management functions
generate_service_account_key() {
    # Remove old key if it exists
    if [ -f "$KEY_FILE" ]; then
        log_warn "Removing old key $KEY_FILE..."
        rm $KEY_FILE
    fi

    log_info "Generating JSON key..."
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL

    # Verify file was created
    if [ -f "$KEY_FILE" ]; then
        log_info "JSON key created successfully: $KEY_FILE"
        chmod 600 $KEY_FILE  # Secure the file
    else
        log_error "Failed to create JSON key"
        exit 1
    fi
}

# Configuration file management functions
create_env_file() {
    log_info "Creating .env file..."

    cat > ./docker/.env << EOF
# Google Cloud Platform Configuration
GOOGLE_PROJECT=$PROJECT_ID
GOOGLE_CREDENTIALS=$(cat $KEY_FILE | tr -s '\n' ' ')
GOOGLE_REGION=europe-west1
GOOGLE_ZONE=europe-west1-a

# Terraform Configuration
TF_IN_AUTOMATION=1
TF_INPUT=0

# GKE Configuration
TF_VAR_gcp_project_id=$PROJECT_ID
TF_VAR_gke_cluster_name=whispr-messenger-cluster

EOF

}

delete_service_account_key() {
    if [ -f "$KEY_FILE" ]; then
        log_info "Deleting service account key $KEY_FILE..."
        rm $KEY_FILE
    else
        log_warn "Key file $KEY_FILE does not exist"
    fi
}

update_gitignore() {
    if ! grep -q "$KEY_FILE" .gitignore 2>/dev/null; then
        echo "$KEY_FILE" >> .gitignore
        log_info "Added $KEY_FILE to .gitignore"
    fi
}


# Main execution function
main() {
    validate_arguments "$@"
    check_gcloud_installation
    authenticate_gcp
    configure_project
    enable_required_apis
    create_service_account
    assign_service_account_roles
    generate_service_account_key
    create_env_file
    delete_service_account_key
    update_gitignore
}

# Execute main function with all arguments
main "$@"