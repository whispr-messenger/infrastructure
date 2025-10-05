# Guide de configuration kubectl pour l'équipe plateforme

Ce guide explique comment les membres de l'équipe plateforme doivent configurer leur client kubectl pour accéder au cluster GKE avec le service account partagé.

## Prérequis pour l'équipe

1. Avoir reçu le fichier `platform-engineers-key.json` de manière sécurisée
2. Installer `gcloud` CLI : https://cloud.google.com/sdk/docs/install
3. Installer `kubectl` : https://kubernetes.io/docs/tasks/tools/

## Configuration étape par étape

### Étape 1 : Authentification avec le service account

```bash
# 1. Placer la clé dans un endroit sécurisé
mkdir -p ~/.config/gcloud/
mv platform-engineers-key.json ~/.config/gcloud/
chmod 600 ~/.config/gcloud/platform-engineers-key.json

# 2. S'authentifier avec le service account
gcloud auth activate-service-account --key-file=~/.config/gcloud/platform-engineers-key.json

# 3. Définir le projet par défaut
gcloud config set project whispr-messenger-472716

# 4. Vérifier l'authentification
gcloud auth list
```

### Étape 2 : Récupérer les credentials du cluster

```bash
# Récupérer les informations du cluster GKE
gcloud container clusters get-credentials whispr-messenger --zone europe-west1-b

# Vérifier que le contexte est configuré
kubectl config current-context
```

### Étape 3 : Tester l'accès

```bash
# Tests de base
kubectl get nodes
kubectl get namespaces

# Tests spécifiques aux permissions de l'équipe plateforme
kubectl get pods -n whispr-prod
kubectl get authorizationpolicies -n whispr-prod
kubectl get pods -n platform-dev

# Test de création (dans le namespace de dev)
kubectl create deployment test --image=nginx -n platform-dev
kubectl delete deployment test -n platform-dev
```

## Vérification des permissions

l'équipe peut vérifier leurs permissions avec :

```bash
# Vérifier les permissions globales
kubectl auth can-i get pods --all-namespaces
kubectl auth can-i create authorizationpolicies -n whispr-prod
kubectl auth can-i delete namespace argocd  # Devrait dire "no"

# Vérifier les permissions par namespace
kubectl auth can-i "*" -n platform-dev  # Devrait dire "yes"
kubectl auth can-i create pods -n whispr-prod  # Devrait dire "yes"
```

## Ce que l'équipe peut faire

### Dans le namespace `platform-dev` :
- Créer/modifier/supprimer toutes les ressources
- Tester ses configurations Istio en toute liberté
- Expérimenter sans risque

### Dans le namespace `whispr-prod` :
- Voir toutes les ressources
- Créer/modifier les politiques Istio (AuthorizationPolicy, PeerAuthentication)
- Créer/modifier les configurations réseau Istio (VirtualService, DestinationRule)
- Accéder aux logs pour debugging
- Faire du port-forwarding pour tester

### Globalement :
- Voir tous les pods, services, deployments (lecture seule)
- Accéder aux logs de debugging
- Voir les événements Kubernetes
- Voir les métriques

## Configuration avancée (optionnelle)

### Créer un alias pour simplifier

```bash
# Ajouter dans ~/.bashrc ou ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kga='kubectl get authorizationpolicies'

# Pour basculer facilement entre namespaces
alias kn-prod='kubectl config set-context --current --namespace=whispr-prod'
alias kn-dev='kubectl config set-context --current --namespace=platform-dev'
```

### Configuration de kubectx/kubens (recommandé)

```bash
# Installation sur macOS
brew install kubectx

# Installation sur Linux
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Usage
kubens whispr-prod  # Basculer vers whispr-prod
kubens platform-dev  # Basculer vers platform-dev
```

## 🔐 Sécurité

### Bonnes pratiques pour les membres de l'équipe :

1. **Protéger la clé JSON :**
   ```bash
   chmod 600 ~/.config/gcloud/platform-engineers-key.json
   ```

2. **Ne jamais commiter la clé :**
   ```bash
   # Ajouter dans ~/.gitignore global
   echo "*.json" >> ~/.gitignore_global
   git config --global core.excludesfile ~/.gitignore_global
   ```

3. **Rotation régulière :**
   - La clé doit être renouvelée tous les 90 jours
   - Demander une nouvelle clé si compromise

4. **Utiliser un namespace dédié pour les tests :**
   - Toujours tester dans `platform-dev` d'abord
   - Ne modifier `whispr-prod` qu'après validation

## 🆘 Troubleshooting

### Problème : "Unable to connect to the server"
```bash
# Vérifier l'authentification
gcloud auth list
gcloud auth activate-service-account --key-file=~/.config/gcloud/platform-engineers-key.json
```

### Problème : "Forbidden" ou permissions insuffisantes
```bash
# Vérifier les permissions
kubectl auth can-i get pods -n whispr-prod
kubectl auth whoami  # Vérifier l'identité utilisée
```

### Problème : Mauvais contexte kubectl
```bash
# Lister les contextes disponibles
kubectl config get-contexts

# Basculer vers le bon contexte
kubectl config use-context gke_PROJECT_ID_europe-west1-b_whispr-messenger
```

### Problème : Clé expirée
```bash
# Demander une nouvelle clé à l'admin
# Puis réactiver l'authentification
gcloud auth activate-service-account --key-file=NEW_KEY.json
```

## 📞 Support

En cas de problème, l'équipe peut :
1. Vérifier leurs permissions : `kubectl auth can-i --list`
2. Vérifier son identité : `kubectl auth whoami`
3. Vérifier la connectivité : `kubectl cluster-info`
4. Contacter l'équipe admin avec les logs d'erreur

---

**Note importante :** Ce service account est partagé par l'équipe plateforme. Toutes les actions sont auditées par Kubernetes.