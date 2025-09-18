#!/bin/bash

set -e

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables
PROJECT_ID="whisp-469509"
SA_NAME="terraform-gke"
SA_EMAIL=""
KEY_FILE="gcp-terraform-key.json"

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

check_billing() {
    log_info "Checking billing..."
    BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")
    if [ "$BILLING_ENABLED" != "True" ]; then
        log_warn "Billing is not enabled on this project. Enable it in the GCP console."
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

    cat > .env << EOF
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
TF_VAR_gke_cluster_name=whispr-cluster

EOF

}

create_terraform_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        log_info "Creating terraform.tfvars file..."
        cat > terraform.tfvars << EOF
# GCP Project Configuration
project_id = "$PROJECT_ID"
region     = "europe-west1"
zone       = "europe-west1-a"

# GKE Cluster Configuration
cluster_name = "my-gke-cluster"
node_count   = 3
machine_type = "e2-medium"

# Network Configuration
network_name = "gke-network"
subnet_name  = "gke-subnet"
subnet_cidr  = "10.10.0.0/24"

# Labels
environment = "development"
team        = "infrastructure"

# Node Configuration
preemptible_nodes = true
disk_size_gb      = 30
disk_type         = "pd-standard"

# Security Configuration
enable_network_policy       = true
enable_pod_security_policy  = false

# Monitoring and Logging
enable_logging_service    = true
enable_monitoring_service = true
EOF
        log_info "terraform.tfvars file created. Modify it according to your needs."
    else
        log_warn "terraform.tfvars file already exists. Update it manually if necessary."
    fi
}

update_gitignore() {
    if ! grep -q "$KEY_FILE" .gitignore 2>/dev/null; then
        echo "$KEY_FILE" >> .gitignore
        log_info "Added $KEY_FILE to .gitignore"
    fi
}

# Information and instruction functions
display_final_instructions() {
    log_info "✅ Setup completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Review and modify .env and terraform.tfvars files according to your needs"
    echo "2. Start the development environment: just up"
    echo "3. Initialize Terraform: just init"
    echo "4. Plan the deployment: just plan"
    echo "5. Deploy the infrastructure: just apply"
    echo
    log_warn "⚠️  Security:"
    echo "- The file $KEY_FILE contains sensitive credentials"
    echo "- It has been added to .gitignore to prevent accidental commits"
    echo "- Share these credentials securely with your team"
    echo
    log_info "For more information, see the README.md"
}

# Main execution function
main() {
    validate_arguments "$@"
    check_gcloud_installation
    authenticate_gcp
    configure_project
    check_billing
    enable_required_apis
    create_service_account
    assign_service_account_roles
    generate_service_account_key
    create_env_file
    create_terraform_tfvars
    update_gitignore
    display_final_instructions
}

# Execute main function with all arguments
main "$@"