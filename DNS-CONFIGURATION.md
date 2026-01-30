# Configuration DNS pour whispr.fr

Ce document explique comment configurer les enregistrements DNS chez one.com pour pointer vers votre cluster Kubernetes.

## Prérequis

1. Accès à votre compte one.com
2. L'adresse IP publique du LoadBalancer Istio de votre cluster

## Récupérer l'IP Publique du Cluster

Connectez-vous à votre cluster GKE et exécutez :

```bash
# Se connecter au cluster
gcloud container clusters get-credentials whispr-messenger \
  --region=europe-west1-b \
  --project=tranquil-harbor-480911-k9

# Récupérer l'IP du LoadBalancer Istio
kubectl get svc -n istio-system istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Notez cette adresse IP, vous en aurez besoin pour la configuration DNS.

## Configuration DNS chez one.com

### Étape 1 : Accéder aux Paramètres DNS

1. Connectez-vous sur https://www.one.com/admin/
2. Sélectionnez votre domaine **whispr.fr**
3. Allez dans **DNS Settings** ou **Paramètres DNS**

### Étape 2 : Créer les Enregistrements A

Créez les enregistrements A suivants (remplacez `<IP_CLUSTER>` par l'IP récupérée ci-dessus) :

| Type | Nom | Valeur | TTL |
|------|-----|--------|-----|
| A | @ | `<IP_CLUSTER>` | 3600 |
| A | www | `<IP_CLUSTER>` | 3600 |
| A | argocd | `<IP_CLUSTER>` | 3600 |
| A | prometheus | `<IP_CLUSTER>` | 3600 |
| A | grafana | `<IP_CLUSTER>` | 3600 |
| A | sonarqube | `<IP_CLUSTER>` | 3600 |

### Explications

- **@** : Représente le domaine racine `whispr.fr`
- **www** : Sous-domaine `www.whispr.fr` (sera redirigé vers `whispr.fr` par Istio)
- **argocd** : Interface ArgoCD pour le GitOps
- **prometheus** : Interface Prometheus pour le monitoring
- **grafana** : Dashboards Grafana
- **sonarqube** : Analyse de qualité de code

## Vérification de la Propagation DNS

La propagation DNS peut prendre de 5 minutes à 48 heures (généralement 15-30 minutes).

Pour vérifier que les enregistrements DNS sont actifs :

```bash
# Vérifier le domaine principal
nslookup whispr.fr

# Vérifier les sous-domaines
nslookup www.whispr.fr
nslookup argocd.whispr.fr
nslookup prometheus.whispr.fr
nslookup grafana.whispr.fr
nslookup sonarqube.whispr.fr
```

Vous pouvez également utiliser des outils en ligne :
- https://dnschecker.org/
- https://www.whatsmydns.net/

## Validation des Certificats TLS

Une fois les enregistrements DNS propagés, cert-manager va automatiquement émettre les certificats TLS via Let's Encrypt.

Pour vérifier l'état des certificats :

```bash
# Vérifier tous les certificats
kubectl get certificate -A

# Vérifier le certificat Istio Gateway
kubectl describe certificate istio-gateway-tls -n whispr-prod

# Vérifier le certificat ArgoCD
kubectl describe certificate argocd-server-tls -n argocd
```

Les certificats doivent avoir le statut `Ready: True`.

## Accès aux Services

Une fois les certificats émis, vous pouvez accéder aux services via HTTPS :

- **Application principale** : https://whispr.fr
- **ArgoCD** : https://argocd.whispr.fr
- **Prometheus** : https://prometheus.whispr.fr
- **Grafana** : https://grafana.whispr.fr
- **SonarQube** : https://sonarqube.whispr.fr

## Dépannage

### Les certificats ne sont pas émis

Si les certificats restent en état `Pending` :

```bash
# Vérifier les logs de cert-manager
kubectl logs -n cert-manager deploy/cert-manager

# Vérifier les challenges ACME
kubectl get challenges -A
```

**Causes communes** :
- DNS pas encore propagé (attendre 30 minutes)
- Firewall bloquant le port 80 (nécessaire pour la validation HTTP-01)
- Rate limit Let's Encrypt (max 5 certificats par semaine pour le même domaine)

### Le site n'est pas accessible

1. Vérifier que le DNS pointe vers la bonne IP
2. Vérifier que les pods Istio sont en cours d'exécution :
   ```bash
   kubectl get pods -n istio-system
   ```
3. Vérifier les logs du gateway :
   ```bash
   kubectl logs -n istio-system -l app=istio-ingressgateway
   ```

## Mise à Jour du Callback GitHub OAuth

N'oubliez pas de mettre à jour le callback URL dans votre application GitHub OAuth :

1. Allez sur https://github.com/organizations/whispr-messenger/settings/applications
2. Sélectionnez votre OAuth App
3. Mettez à jour **Authorization callback URL** : `https://argocd.whispr.fr/api/dex/callback`
