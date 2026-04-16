#!/usr/bin/env bash
#
# Bootstrap du preprod devzeyu (WHISPR-912)
#
# Installe ArgoCD dans le cluster k3d `whispr-dev`, provisionne les secrets
# (PostgreSQL, MinIO, JWT, imagePullSecret GHCR optionnel), applique le
# app-of-apps `whispr-preprod-devzeyu-root` depuis la branche `zeyu/preprod`
# du depot `whispr-messenger/infrastructure`.
#
# Usage :
#   ./bootstrap.sh                 # bootstrap complet
#   ./bootstrap.sh --refresh-apps  # seulement re-applique le root app
#   ./bootstrap.sh --help
#
# Variables d'environnement optionnelles :
#   GHCR_USER   utilisateur GitHub (pour imagePullSecret si packages prives)
#   GHCR_TOKEN  PAT GitHub (scope read:packages)
#
# Secrets generes sont ecrits dans /home/pc/.whispr-preprod/secrets.env
# en mode 0600. Non commit en git.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# --- couleurs -----------------------------------------------------------------
c_info='\033[1;34m' ; c_ok='\033[1;32m' ; c_warn='\033[1;33m' ; c_err='\033[1;31m' ; c_rst='\033[0m'
log()  { echo -e "${c_info}==>${c_rst} $*"; }
ok()   { echo -e "${c_ok}OK${c_rst}  $*"; }
warn() { echo -e "${c_warn}!!${c_rst}  $*" >&2; }
die()  { echo -e "${c_err}ERR${c_rst} $*" >&2 ; exit 1 ; }

# --- constantes ---------------------------------------------------------------
CLUSTER_CONTEXT="k3d-whispr-dev"
ARGOCD_NS="argocd"
ARGOCD_CHART_VERSION="7.7.7"
SECRETS_DIR="${HOME}/.whispr-preprod"
SECRETS_FILE="${SECRETS_DIR}/secrets.env"
ROOT_APP_PATH="${REPO_ROOT}/argocd-preprod-devzeyu/root.yaml"
SHARED_JWT_PATH="${REPO_ROOT}/k8s/whispr/preprod/infra/jwt-keys.yaml"

# --- pre-checks ---------------------------------------------------------------
preflight() {
    log "Verifications initiales"
    command -v kubectl >/dev/null || die "kubectl manquant"
    command -v helm    >/dev/null || die "helm manquant"
    command -v k3d     >/dev/null || warn "k3d absent (ok si cluster deja present)"

    if ! kubectl config get-contexts "${CLUSTER_CONTEXT}" >/dev/null 2>&1; then
        die "Contexte kubectl '${CLUSTER_CONTEXT}' introuvable"
    fi
    kubectl config use-context "${CLUSTER_CONTEXT}" >/dev/null
    kubectl cluster-info >/dev/null || die "Cluster ${CLUSTER_CONTEXT} injoignable"

    [ -f "${ROOT_APP_PATH}" ] || die "Fichier introuvable : ${ROOT_APP_PATH}"
    [ -f "${SHARED_JWT_PATH}" ] || die "JWT keys introuvables : ${SHARED_JWT_PATH}"
    ok "Preflight"
}

# --- generation de secrets ----------------------------------------------------
rand_b64() { head -c "${1:-32}" /dev/urandom | base64 | tr -d '=/+\n' | head -c "${1:-32}" ; }

ensure_secrets_file() {
    mkdir -p "${SECRETS_DIR}"
    chmod 700 "${SECRETS_DIR}"
    if [ ! -f "${SECRETS_FILE}" ]; then
        log "Generation des secrets dans ${SECRETS_FILE}"
        cat > "${SECRETS_FILE}" <<ENVEOF
# whispr preprod devzeyu secrets (WHISPR-912)
# NE JAMAIS commit ce fichier. Mode 0600.
PG_PASSWORD=$(rand_b64 32)
MINIO_ROOT_USER=whispr-$(rand_b64 8 | tr '[:upper:]' '[:lower:]')
MINIO_ROOT_PASSWORD=$(rand_b64 40)
ARGOCD_ADMIN_PASSWORD=$(rand_b64 24)
SONAR_ADMIN_PASSWORD=$(rand_b64 24)
ENVEOF
        chmod 600 "${SECRETS_FILE}"
        ok "Secrets generes"
    else
        log "Reutilisation de ${SECRETS_FILE}"
    fi
    # shellcheck disable=SC1090
    set -a ; source "${SECRETS_FILE}" ; set +a
}

# --- namespaces ---------------------------------------------------------------
ensure_namespaces() {
    log "Creation des namespaces"
    for ns in argocd whispr-preprod postgresql redis minio sonarqube ; do
        kubectl get ns "${ns}" >/dev/null 2>&1 || kubectl create ns "${ns}"
    done
    ok "Namespaces prets"
}

# --- secrets kubernetes -------------------------------------------------------
apply_secret() {
    local ns="$1" name="$2" ; shift 2
    local args=()
    for kv in "$@" ; do args+=(--from-literal="${kv}") ; done
    kubectl -n "${ns}" create secret generic "${name}" "${args[@]}" \
        --dry-run=client -o yaml | kubectl apply -f -
}

create_infra_secrets() {
    log "Secrets infra"
    apply_secret postgresql postgresql-credentials \
        username=postgres \
        password="${PG_PASSWORD}"

    apply_secret minio minio-credentials \
        root-user="${MINIO_ROOT_USER}" \
        root-password="${MINIO_ROOT_PASSWORD}"

    apply_secret sonarqube sonarqube-jdbc \
        password="${PG_PASSWORD}"

    ok "Secrets infra appliques"
}

create_service_secrets() {
    log "Secrets des microservices"
    local common_env=(
        DB_HOST=postgresql.postgresql.svc.cluster.local
        DB_PORT=5432
        DB_USER=postgres
        DB_PASSWORD="${PG_PASSWORD}"
        REDIS_HOST=redis-master.redis.svc.cluster.local
        REDIS_PORT=6379
        REDIS_PASSWORD=
        NODE_ENV=preprod
        LOG_LEVEL=info
    )

    # auth-service : JWT signer + DB auth_service
    apply_secret whispr-preprod auth-service-env \
        "${common_env[@]}" \
        DB_NAME=auth_service \
        JWT_PRIVATE_KEY_PATH=/app/secrets/jwt_private.pem \
        JWT_PUBLIC_KEY_PATH=/app/secrets/jwt_public.pem

    # user-service : DB user_service, pas de JWT signing
    apply_secret whispr-preprod user-service-env \
        "${common_env[@]}" \
        DB_NAME=user_service \
        JWT_PUBLIC_KEY_PATH=/app/secrets/jwt_public.pem

    # media-service : + S3/MinIO
    apply_secret whispr-preprod media-service-env \
        "${common_env[@]}" \
        DB_NAME=media_service \
        JWT_PUBLIC_KEY_PATH=/app/secrets/jwt_public.pem \
        S3_ENDPOINT=http://minio.minio.svc.cluster.local:9000 \
        S3_REGION=us-east-1 \
        S3_BUCKET=whispr-media \
        S3_ACCESS_KEY="${MINIO_ROOT_USER}" \
        S3_SECRET_KEY="${MINIO_ROOT_PASSWORD}" \
        S3_FORCE_PATH_STYLE=true \
        MINIO_ENDPOINT=http://minio.minio.svc.cluster.local:9000 \
        MINIO_ACCESS_KEY="${MINIO_ROOT_USER}" \
        MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD}" \
        MINIO_BUCKET=whispr-media

    # messaging-service (Elixir) — JWT_JWKS_URL explicite car le défaut pointe sur port 80
    apply_secret whispr-preprod messaging-service-env \
        "${common_env[@]}" \
        DB_NAME=messaging_service \
        JWT_PUBLIC_KEY_PATH=/app/secrets/jwt_public.pem \
        JWT_JWKS_URL=http://auth-service.whispr-preprod.svc.cluster.local:3010/auth/.well-known/jwks.json \
        SECRET_KEY_BASE="$(rand_b64 64)" \
        PHX_HOST=whispr.devzeyu.com \
        PHX_PORT=4010

    # notification-service
    apply_secret whispr-preprod notification-service-env \
        "${common_env[@]}" \
        DB_NAME=notification_service \
        JWT_PUBLIC_KEY_PATH=/app/secrets/jwt_public.pem

    # scheduling-service (NestJS) — JWT_JWKS_URL explicite

    apply_secret whispr-preprod scheduling-service-env \
        "${common_env[@]}" \
        DB_NAME=scheduling_service \
        JWT_PUBLIC_KEY_PATH=/app/secrets/jwt_public.pem \
        JWT_JWKS_URL=http://auth-service.whispr-preprod.svc.cluster.local:3010/auth/.well-known/jwks.json \
        SECRET_KEY_BASE="$(rand_b64 64)" \
        PHX_HOST=whispr.devzeyu.com \
        PHX_PORT=3013

    ok "Secrets microservices appliques"
}

apply_jwt_keys() {
    log "Application du secret jwt-keys (reutilise la cle partagee preprod)"
    kubectl -n whispr-preprod apply -f "${SHARED_JWT_PATH}"
    ok "jwt-keys en place"
}

create_ghcr_pull_secret() {
    if [ -z "${GHCR_TOKEN:-}" ] || [ -z "${GHCR_USER:-}" ] ; then
        log "GHCR_USER/GHCR_TOKEN non fournis : skip imagePullSecret (images supposees publiques)"
        return
    fi
    log "Creation imagePullSecret ghcr-pull dans whispr-preprod"
    kubectl -n whispr-preprod create secret docker-registry ghcr-pull \
        --docker-server=ghcr.io \
        --docker-username="${GHCR_USER}" \
        --docker-password="${GHCR_TOKEN}" \
        --docker-email="${GHCR_USER}@users.noreply.github.com" \
        --dry-run=client -o yaml | kubectl apply -f -
    ok "ghcr-pull cree"
}

# --- ArgoCD -------------------------------------------------------------------
install_argocd() {
    log "Installation ArgoCD (helm) dans ns ${ARGOCD_NS}"
    helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
    helm repo update argo >/dev/null

    local bcrypt_pw
    bcrypt_pw="$(
      kubectl -n ${ARGOCD_NS} get secret argocd-secret -o jsonpath='{.data.admin\.password}' 2>/dev/null | base64 -d || true
    )"

    helm upgrade --install argocd argo/argo-cd \
        --namespace "${ARGOCD_NS}" \
        --version "${ARGOCD_CHART_VERSION}" \
        --set configs.params."server\.rootpath"=/argocd \
        --set configs.params."server\.insecure"=true \
        --set configs.params."server\.disable\.auth"=false \
        --set server.extraArgs="{--rootpath,/argocd,--insecure}" \
        --set redis-ha.enabled=false \
        --set controller.replicas=1 \
        --set server.replicas=1 \
        --set repoServer.replicas=1 \
        --set applicationSet.replicas=1 \
        --wait --timeout 10m

    ok "ArgoCD installe"
}

set_argocd_admin_pw() {
    log "Configuration du mot de passe admin ArgoCD"
    local bcrypt_hash
    bcrypt_hash="$(htpasswd -bnBC 10 "" "${ARGOCD_ADMIN_PASSWORD}" 2>/dev/null | tr -d ':\n' | sed 's/^[$]2y/$2a/' || true)"
    if [ -z "${bcrypt_hash}" ] ; then
        warn "htpasswd absent : utiliser un pod temporaire"
        bcrypt_hash="$(
            kubectl -n ${ARGOCD_NS} run argocd-bcrypt --rm -i --restart=Never --quiet \
                --image=httpd:2.4-alpine --command -- \
                htpasswd -bnBC 10 '' "${ARGOCD_ADMIN_PASSWORD}" 2>/dev/null \
                | tr -d ':\n' | sed 's/^[$]2y/$2a/'
        )"
    fi
    kubectl -n "${ARGOCD_NS}" patch secret argocd-secret \
        -p "{\"stringData\": {\"admin.password\": \"${bcrypt_hash}\", \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"}}" \
        --type merge
    ok "Mot de passe admin applique (voir ${SECRETS_FILE})"
}

apply_root_app() {
    log "Application du root app-of-apps"
    kubectl apply -f "${ROOT_APP_PATH}"
    ok "Root app applique"
}

wait_for_argocd_sync() {
    log "Attente initiale de la sync ArgoCD (5 min max)"
    local deadline=$(( $(date +%s) + 300 ))
    while [ $(date +%s) -lt "${deadline}" ] ; do
        local ready
        ready="$(kubectl -n ${ARGOCD_NS} get application -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.sync.status}{"/"}{.status.health.status}{"\n"}{end}' 2>/dev/null || true)"
        echo "${ready}" | sed 's/^/    /'
        if echo "${ready}" | grep -vE '=Synced/Healthy$' | grep -q '=' ; then
            sleep 15
        else
            ok "Toutes les applications Synced/Healthy"
            return 0
        fi
    done
    warn "Timeout : certaines apps ne sont pas encore Synced/Healthy ; verifier via ArgoCD UI"
}

print_summary() {
    echo ""
    echo "================================================================="
    echo " Bootstrap termine (WHISPR-912)"
    echo "================================================================="
    echo " ArgoCD UI    : https://whispr.devzeyu.com/argocd/"
    echo " SonarQube UI : https://whispr.devzeyu.com/sonarqube/"
    echo " API         : https://whispr.devzeyu.com/{auth,user,media,messaging,notification,scheduling}/..."
    echo ""
    echo " Mots de passe : ${SECRETS_FILE}"
    echo "================================================================="
}

# --- main ---------------------------------------------------------------------
main() {
    case "${1:-}" in
        -h|--help)
            sed -n '2,18p' "$0"
            exit 0
            ;;
        --refresh-apps)
            preflight
            apply_root_app
            exit 0
            ;;
        "")
            ;;
        *)
            die "Option inconnue: $1"
            ;;
    esac

    preflight
    ensure_secrets_file
    ensure_namespaces
    create_infra_secrets
    apply_jwt_keys
    create_service_secrets
    create_ghcr_pull_secret
    install_argocd
    set_argocd_admin_pw
    apply_root_app
    wait_for_argocd_sync
    tune_argocd_reconciliation
    ensure_postgres_roles
    print_summary
}

# Réduit l'intervalle de polling ArgoCD de 180s à 30s (preprod).
# Amélioration purement locale, aucun effet sur d'autres clusters.
tune_argocd_reconciliation() {
    log "Réglage ArgoCD timeout.reconciliation=30s"
    kubectl -n "${ARGOCD_NS}" patch cm argocd-cm --type=merge \
        -p '{"data":{"timeout.reconciliation":"30s"}}' >/dev/null
    kubectl -n "${ARGOCD_NS}" rollout restart statefulset argocd-application-controller >/dev/null
    ok "ArgoCD reconciliation 30s"
}

# Crée les rôles PostgreSQL non-superuser dont certains services ont besoin.
# - media_app : rôle de connexion utilisé par media-service (RLS refuse superuser)
# - media_user : rôle cible de GRANT utilisé par les migrations media-service
# Les rôles sont créés idempotemment ; les mots de passe vivent uniquement en DB.
ensure_postgres_roles() {
    log "Création des rôles PostgreSQL non-superuser"
    # Attendre que le StatefulSet postgresql soit prêt (géré par ArgoCD).
    kubectl -n postgresql wait --for=condition=ready pod postgresql-0 --timeout=180s >/dev/null 2>&1 || true

    local media_app_pass
    media_app_pass="$(rand_b64 24)"
    local media_user_pass
    media_user_pass="$(rand_b64 24)"

    kubectl -n postgresql exec postgresql-0 -- psql -U postgres -v ON_ERROR_STOP=1 <<PSQL_EOF >/dev/null 2>&1 || true
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'media_app') THEN
        CREATE ROLE media_app WITH LOGIN PASSWORD '${media_app_pass}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'media_user') THEN
        CREATE ROLE media_user WITH LOGIN PASSWORD '${media_user_pass}';
    END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE media_service TO media_app;
GRANT ALL PRIVILEGES ON DATABASE media_service TO media_user;
ALTER DATABASE media_service OWNER TO media_app;
PSQL_EOF

    # Mise à jour du secret media-service-env pour qu'il utilise media_app en tant
    # que rôle de connexion (required by RLS subscriber in media-service).
    kubectl -n whispr-preprod get secret media-service-env -o json 2>/dev/null \
        | jq --arg u "$(echo -n 'media_app' | base64 -w0)" \
             --arg p "$(echo -n "${media_app_pass}" | base64 -w0)" \
             '.data.DB_USER=$u | .data.DB_USERNAME=$u | .data.DB_PASSWORD=$p' \
        | kubectl apply -f - >/dev/null 2>&1

    ok "Rôles PostgreSQL (media_app, media_user) créés"
}

main "$@"
