#!/bin/bash

# Script decho "Fichiers mis à jour avec ces valeurs:"
echo "  - scripts/platform-engineers/create-platform-enginéers-sa.sh"
echo "  - scripts/platform-engineers/grant-gke-access.sh"
echo "  - scripts/platform-engineers/platform-engineers-rbac.yaml"
echo "  - scripts/platform-engineers/README-kubectl-setup-team.md"
echo "  - scripts/platform-engineers/verify-kubectl-access.sh"fication et mise à jour des configurations
# Affiche les vraies valeurs du cluster et projet

echo "Informations réelles du cluster GKE"
echo "======================================"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
echo "Projet GCP: $PROJECT_ID"

echo ""
echo "Clusters disponibles:"
gcloud container clusters list --format="table(name,location,status)" 2>/dev/null

echo ""
echo "Valeurs à utiliser dans les scripts:"
echo "  PROJECT_ID: $PROJECT_ID"
echo "  CLUSTER_NAME: whispr-messenger"
echo "  CLUSTER_ZONE: europe-west1-b"
echo "  SERVICE_ACCOUNT: platform-engineers@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
echo "Fichiers mis à jour avec ces valeurs:"
echo "  - scripts/create-platform-engineers-sa.sh"
echo "  - scripts/grant-gke-access.sh"
echo "  - scripts/platform-engineers-rbac.yaml"
echo "  - scripts/README-kubectl-setup-david.md"
echo "  - scripts/verify-kubectl-access.sh"

echo ""
echo "Prochaines étapes pour donner accès à un utilisateur :"
echo "  1. ./create-platform-engineers-sa.sh"
echo "  2. kubectl apply -f platform-engineers-rbac.yaml"
echo "  3. Envoyer platform-engineers-key.json à l'utilisateur concerné"