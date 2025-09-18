default:
    @just --list

# Setup GCP credentials and project (requires PROJECT_ID as argument)
[group('gcp')]
setup-gcp project_id:
    chmod +x scripts/setup-gcp.sh
    ./scripts/setup-gcp-project.sh {{project_id}}