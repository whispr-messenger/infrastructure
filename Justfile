default:
    @just --list

# Setup GCP credentials and project (requires PROJECT_ID as argument)
[group('gcp')]
setup-gcp project_id:
    chmod +x scripts/setup-gcp-project.sh
    ./scripts/setup-gcp-project.sh {{project_id}}

# Create ArgoCD static IP
[group('gcp')]
create-argocd-ip:
    chmod +x scripts/create-argocd-ip.sh
    ./scripts/create-argocd-ip.sh

# Show current cluster information
[group('info')]
cluster-info:
    chmod +x scripts/show-cluster-info.sh
    ./scripts/show-cluster-info.sh

# Create platform engineers service account (admin only)
[group('platform')]
create-platform-sa:
    chmod +x scripts/platform-engineers/create-platform-engineers-sa.sh
    ./scripts/platform-engineers/create-platform-engineers-sa.sh

# Apply platform engineers RBAC (admin only) 
[group('platform')]
apply-platform-rbac:
    kubectl apply -f argocd/infrastructure/rbac/platform-engineers-rbac.yaml

# Setup complete platform engineers access (admin only)
[group('platform')]
setup-platform-access: create-platform-sa apply-platform-rbac

# Verify kubectl access (for team members)
[group('platform')]
verify-access:
    chmod +x scripts/platform-engineers/verify-kubectl-access.sh
    ./scripts/platform-engineers/verify-kubectl-access.sh

# Apply specific ArgoCD application
[group('argocd')]
apply-app app:
    kubectl apply -f argocd/applications/{{app}}.yaml

# Apply all ArgoCD applications
[group('argocd')]
apply-all-apps:
    kubectl apply -f argocd/applications/

# Apply ArgoCD root app (app of apps pattern)
[group('argocd')]
apply-root:
    kubectl apply -f argocd/root.yaml

# Sync specific ArgoCD application
[group('argocd')]
sync-app app:
    argocd app sync {{app}}

# Get ArgoCD application status
[group('argocd')]
app-status app:
    argocd app get {{app}}

# Port-forward to ArgoCD server (for local access)
[group('argocd')]
argocd-port-forward:
    kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get all pods in whispr-prod namespace
[group('debug')]
get-pods-prod:
    kubectl get pods -n whispr-prod

# Get all Istio authorization policies
[group('debug')]
get-istio-authz:
    kubectl get authorizationpolicies -A

# Describe a specific pod
[group('debug')]
describe-pod pod namespace='whispr-prod':
    kubectl describe pod {{pod}} -n {{namespace}}

# Get logs from a pod
[group('debug')]
logs pod namespace='whispr-prod' follow='false':
    @if [ "{{follow}}" = "true" ]; then \
        kubectl logs {{pod}} -n {{namespace}} -f; \
    else \
        kubectl logs {{pod}} -n {{namespace}}; \
    fi

# Clean up generated files
[group('clean')]
clean:
    rm -f scripts/platform-engineers/platform-engineers-key.json
    rm -f scripts/*.json