#!/bin/bash

set -e

SERVICES=("messaging-service" "scheduling-service")
ENVIRONMENTS=("development" "staging" "production")

echo "🧪 Test de génération Kustomize pour tous les services"
echo "========================================================"
echo ""

for service in "${SERVICES[@]}"; do
    echo "📦 Service: $service"
    echo "---"

    for env in "${ENVIRONMENTS[@]}"; do
        echo -n "  Testing $env... "

        if kustomize build "$service/k8s/overlays/$env" > /dev/null 2>&1; then
            echo "✅"
        else
            echo "❌"
            echo "    Erreur lors de la génération pour $service/$env"
            kustomize build "$service/k8s/overlays/$env"
            exit 1
        fi
    done

    echo ""
done

echo "✅ Tous les tests ont réussi!"
echo ""
echo "Pour voir les manifestes générés:"
echo "  kustomize build messaging-service/k8s/overlays/production | less"
echo "  kustomize build scheduling-service/k8s/overlays/production | less"
