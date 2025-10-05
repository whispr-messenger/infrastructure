#!/bin/bash

# Script de vérification pour David - Teste l'accès au cluster GKE
# Usage: ./verify-kubectl-access.sh

set -e

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

echo "Verification de l'acces au cluster GKE pour l'equipe plateforme"
echo "================================================================="

# Test 1: Vérifier l'authentification gcloud
log_test "Vérification de l'authentification gcloud..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "platform-engineers"; then
    log_info "Service account platform-engineers actif"
else
    log_error "Service account platform-engineers non trouvé"
    echo "Exécutez: gcloud auth activate-service-account --key-file=platform-engineers-key.json"
    exit 1
fi

# Test 2: Vérifier la connectivité au cluster
log_test "Vérification de la connectivité au cluster..."
if kubectl cluster-info >/dev/null 2>&1; then
    log_info "Connectivité au cluster OK"
else
    log_error "Impossible de se connecter au cluster"
    echo "Exécutez: gcloud container clusters get-credentials whispr-messenger --zone europe-west1-b"
    exit 1
fi

# Test 3: Vérifier l'identité dans Kubernetes
log_test "Vérification de l'identité Kubernetes..."
CURRENT_USER=$(kubectl auth whoami 2>/dev/null || echo "unknown")
if echo "$CURRENT_USER" | grep -q "platform-engineers"; then
    log_info "Identité Kubernetes: $CURRENT_USER"
else
    log_warn "Identité inattendue: $CURRENT_USER"
fi

# Test 4: Permissions de base
log_test "Test des permissions de base..."

# Lecture des nodes
if kubectl get nodes >/dev/null 2>&1; then
    log_info "Lecture des nodes: OK"
else
    log_error "Impossible de lire les nodes"
fi

# Lecture des namespaces
if kubectl get namespaces >/dev/null 2>&1; then
    log_info "Lecture des namespaces: OK"
else
    log_error "Impossible de lire les namespaces"
fi

# Test 5: Permissions Istio dans whispr-prod
log_test "Test des permissions Istio dans whispr-prod..."

if kubectl auth can-i create authorizationpolicies -n whispr-prod >/dev/null 2>&1; then
    log_info "Création AuthorizationPolicies dans whispr-prod: OK"
else
    log_error "Impossible de créer des AuthorizationPolicies dans whispr-prod"
fi

if kubectl auth can-i get pods -n whispr-prod >/dev/null 2>&1; then
    log_info "Lecture des pods dans whispr-prod: OK"
else
    log_error "Impossible de lire les pods dans whispr-prod"
fi

# Test 6: Permissions complètes dans platform-dev
log_test "Test des permissions dans platform-dev..."

if kubectl auth can-i "*" -n platform-dev >/dev/null 2>&1; then
    log_info "Permissions complètes dans platform-dev: OK"
else
    log_error "Permissions insuffisantes dans platform-dev"
fi

# Test 7: Vérifier les restrictions (doit échouer)
log_test "Vérification des restrictions de sécurité..."

if kubectl auth can-i delete namespace argocd >/dev/null 2>&1; then
    log_error "ATTENTION: Vous pouvez supprimer des namespaces critiques!"
else
    log_info "Restriction sur suppression des namespaces: OK"
fi

# Test 8: Test d'accès aux logs
log_test "Test d'accès aux logs..."

if kubectl auth can-i get pods/log --all-namespaces >/dev/null 2>&1; then
    log_info "Accès aux logs: OK"
else
    log_warn "Accès aux logs limité"
fi

# Résumé des namespaces accessibles
echo ""
echo "📂 Namespaces accessibles:"
kubectl get namespaces --no-headers 2>/dev/null | while read ns rest; do
    if kubectl auth can-i get pods -n "$ns" >/dev/null 2>&1; then
        if kubectl auth can-i create pods -n "$ns" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $ns (lecture + écriture)"
        else
            echo -e "  ${YELLOW}○${NC} $ns (lecture seule)"
        fi
    fi
done

# Commandes utiles
echo ""
echo "Commandes utiles pour debuter:"
echo "  kubectl get pods -n whispr-prod          # Voir les pods de production"
echo "  kubectl get authorizationpolicies -A     # Voir toutes les politiques Istio"
echo "  kubectl logs POD_NAME -n whispr-prod     # Voir les logs d'un pod"
echo "  kubectl config set-context --current --namespace=platform-dev  # Basculer vers votre namespace"
echo ""
echo "Namespace recommande pour vos tests: platform-dev"
echo "   kubectl config set-context --current --namespace=platform-dev"

echo ""
log_info "Vérification terminée! Vous pouvez commencer à travailler avec kubectl."