# Tiltfile — Whispr Messenger local Kubernetes development environment
#
# Prerequisites:
#   - k3d cluster running: ./scripts/dev-setup.sh
#   - kubectl context set to k3d-whispr-dev
#
# Usage: tilt up
#
# Services are exposed via Ingress at localhost:8080:
#   - /auth/*     → auth-service
#   - /user/*     → user-service
#   - /media/*    → media-service
#   - /scheduling/* → scheduling-service
#   - /messaging/* → messaging-service
#   - /notification/* → notification-service

secret_settings(disable_scrub = True)
default_registry(host = 'localhost:5000', host_from_cluster='k3d-whispr-dev-registry:5000')

# ---------------------------------------------------------------------------
# Namespace and shared infrastructure
# ---------------------------------------------------------------------------
k8s_yaml('k8s/whispr/development/namespace.yaml')

k8s_yaml([
    'k8s/whispr/development/postgres/configmap.yaml',
    'k8s/whispr/development/postgres/secret.yaml',
    'k8s/whispr/development/postgres/deployment.yaml',
    'k8s/whispr/development/postgres/service.yaml',
])

k8s_resource('postgres', port_forwards=['5432:5432'], labels=['infrastructure'])

k8s_yaml([
    'k8s/whispr/development/redis/deployment.yaml',
    'k8s/whispr/development/redis/service.yaml',
])

k8s_resource('redis', port_forwards=['6379:6379'], labels=['infrastructure'])

k8s_yaml([
    'k8s/whispr/development/minio/secret.yaml',
    'k8s/whispr/development/minio/deployment.yaml',
    'k8s/whispr/development/minio/service.yaml',
])

k8s_resource('minio', port_forwards=['9000:9000', '9001:9001'], labels=['infrastructure'])

# ---------------------------------------------------------------------------
# Ingress — single entry point, like production
# ---------------------------------------------------------------------------
k8s_yaml('k8s/whispr/development/ingress.yaml')

k8s_resource(
    objects = ['whispr-dev-ingress:ingress'],
    new_name = 'ingress',
    labels = ['infrastructure'],
)

# ---------------------------------------------------------------------------
# Helper: build a NestJS service with live_update (TypeScript hot-reload)
# ---------------------------------------------------------------------------

def nestjs_service(name, context, debug_port=9229):
    image = name + ':latest'
    abs_context = os.path.abspath(context)

    docker_build(
        image,
        context = abs_context,
        dockerfile = abs_context + '/docker/dev/Dockerfile',
        live_update = [
            sync(abs_context + '/src', '/workspace/src'),
            run('cd /workspace && npm run build', trigger = [abs_context + '/src']),
        ],
    )

    k8s_yaml([
        'k8s/whispr/development/' + name + '/configmap.yaml',
        'k8s/whispr/development/' + name + '/secret.yaml',
        'k8s/whispr/development/' + name + '/deployment.yaml',
        'k8s/whispr/development/' + name + '/service.yaml',
    ])

    k8s_resource(
        name,
        port_forwards = [
            str(debug_port) + ':9229',
        ],
        resource_deps = ['postgres', 'redis'],
        labels = ['services'],
    )

# ---------------------------------------------------------------------------
# Helper: build an Elixir/Phoenix service with live_update
# ---------------------------------------------------------------------------
def phoenix_service(name, context, http_port=None, grpc_port=None):
    image = name + ':latest'
    abs_context = os.path.abspath(context)

    # Build live_update syncs — only sync priv/ if the directory exists on the host
    live_update_steps = [
        sync(abs_context + '/lib', '/app/lib'),
    ]

    if os.path.exists(abs_context + '/priv'):
        live_update_steps.append(sync(abs_context + '/priv', '/app/priv'))

    # Recompile and send SIGUSR1 to the running beam.smp so Phoenix hot-reloads
    live_update_steps.append(
        run(
            'cd /app && mix compile && kill -USR1 $(pgrep -f "beam.smp" | head -1) 2>/dev/null || true',
            trigger = [abs_context + '/lib'],
        )
    )

    docker_build(
        image,
        context = abs_context,
        dockerfile = abs_context + '/docker/dev/Dockerfile',
        live_update = live_update_steps,
    )

    k8s_yaml([
        'k8s/whispr/development/' + name + '/configmap.yaml',
        'k8s/whispr/development/' + name + '/secret.yaml',
        'k8s/whispr/development/' + name + '/deployment.yaml',
        'k8s/whispr/development/' + name + '/service.yaml',
    ])

    forwards = []
    if http_port != None:
        forwards.append(str(http_port) + ':' + str(http_port))
    if grpc_port != None:
        forwards.append(str(grpc_port) + ':' + str(grpc_port))

    k8s_resource(
        name,
        port_forwards = forwards,
        resource_deps = ['postgres', 'redis'],
        labels = ['services'],
    )

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------

# NestJS services (TypeScript — support live_update)
nestjs_service(
    name       = 'auth-service',
    context    = '../auth-service',
    debug_port = 9229,
)

nestjs_service(
    name       = 'user-service',
    context    = '../user-service',
    debug_port = 9230,
)

nestjs_service(
    name       = 'media-service',
    context    = '../media-service',
    debug_port = 9231,
)

k8s_resource('media-service', resource_deps=['postgres', 'redis', 'minio'])

nestjs_service(
    name       = 'scheduling-service',
    context    = '../scheduling-service',
    debug_port = 9232,
)

# Elixir/Phoenix services
phoenix_service(
    name      = 'notification-service',
    context   = '../notification-service',
    http_port = 4002,
    grpc_port = 4003,
)

phoenix_service(
    name      = 'messaging-service',
    context   = '../messaging-service',
    http_port = 4000,
    grpc_port = 50051,
)
