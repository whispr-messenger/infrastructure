# Tiltfile — Whispr local Kubernetes development environment
#
# Prerequisites:
#   - k3d cluster running: ./scripts/dev-setup.sh
#   - kubectl context set to k3d-whispr-dev
#
# Usage: tilt up

load('ext://helm_resource', 'helm_resource', 'helm_repo')

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------
REGISTRY = 'k3d-whispr-registry:5000'

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

# ---------------------------------------------------------------------------
# Helper: build a NestJS service with live_update (TypeScript hot-reload)
# ---------------------------------------------------------------------------
def nestjs_service(name, context, http_port, grpc_port, health_path):
    image = REGISTRY + '/' + name + ':dev'

    docker_build(
        image,
        context = context,
        dockerfile = context + '/Dockerfile',
        live_update = [
            sync(context + '/src', '/app/src'),
            run('cd /app && npm run build', trigger = [context + '/src']),
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
            str(http_port) + ':' + str(http_port),
            str(grpc_port) + ':' + str(grpc_port),
            '9229:9229',
        ],
        resource_deps = ['postgres', 'redis'],
        labels = ['services'],
    )

# ---------------------------------------------------------------------------
# Helper: build an Elixir/Phoenix service
# ---------------------------------------------------------------------------
def phoenix_service(name, context, http_port, grpc_port):
    image = REGISTRY + '/' + name + ':dev'

    docker_build(
        image,
        context = context,
        dockerfile = context + '/Dockerfile',
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
            str(http_port) + ':' + str(http_port),
            str(grpc_port) + ':' + str(grpc_port),
        ],
        resource_deps = ['postgres', 'redis'],
        labels = ['services'],
    )

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------

# NestJS services (TypeScript — support live_update)
nestjs_service(
    name        = 'auth-service',
    context     = '../auth-service',
    http_port   = 3001,
    grpc_port   = 50056,
    health_path = '/auth/v1/health/ready',
)

nestjs_service(
    name        = 'user-service',
    context     = '../user-service',
    http_port   = 3002,
    grpc_port   = 50055,
    health_path = '/user/v1/health/ready',
)

nestjs_service(
    name        = 'media-service',
    context     = '../media-service',
    http_port   = 3003,
    grpc_port   = 50054,
    health_path = '/media/v1/health/ready',
)

nestjs_service(
    name        = 'scheduling-service',
    context     = '../scheduling-service',
    http_port   = 3004,
    grpc_port   = 50052,
    health_path = '/health/ready',
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
