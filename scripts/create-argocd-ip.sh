#!/bin/bash

# Script pour créer une IP statique globale pour ArgoCD
echo "Création de l'IP statique globale pour ArgoCD..."

# Créer l'IP statique
gcloud compute addresses create argocd-ip \
    --global \
    --description="IP statique pour ArgoCD"

# Afficher l'IP créée
echo "IP statique créée avec succès:"
gcloud compute addresses describe argocd-ip --global --format="value(address)"

echo "Veuillez configurer votre DNS pour pointer argocd.whispr.epitech-msc2026.me vers cette IP"