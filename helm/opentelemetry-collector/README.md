# WHISPR-1067 — OpenTelemetry Collector + Tempo

## Topologie

```
┌───────────────┐   OTLP gRPC   ┌──────────────────┐   OTLP gRPC   ┌─────────┐
│  service Nest │ ────────────▶ │  otel-collector  │ ────────────▶ │  tempo  │
│  / Elixir     │   :4317/:4318 │    (monitoring)  │     :4317     │         │
└───────────────┘               └──────────────────┘               └─────────┘
                                                                         │
                                                                         ▼
                                                                   ┌──────────┐
                                                                   │  grafana │
                                                                   │  Tempo DS│
                                                                   └──────────┘
```

Le collector tourne en `deployment` single-replica dans le namespace
`monitoring`. Il expose :

| Port | Protocole | Usage |
|------|-----------|-------|
| 4317 | gRPC | réception OTLP depuis les services |
| 4318 | HTTP | réception OTLP depuis SDK web / CLI |
| 8888 | HTTP | métriques du collector (scrapées par Prometheus) |

## Variables ENV à poser par service

Chaque service active le trace export avec les variables standard :

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://opentelemetry-collector.monitoring.svc.cluster.local:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_SERVICE_NAME=<service-name>   # ex. auth-service
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=preprod
```

Si `OTEL_EXPORTER_OTLP_ENDPOINT` est absent, les SDK no-op (pas de panique
locale, pas de dépendance dure).

## Plan d'intégration par service

| Service | Stack | SDK à ajouter | Suivi |
|---------|-------|---------------|-------|
| auth-service | NestJS | `@opentelemetry/sdk-node` + auto-instrumentations | ticket séparé |
| user-service | NestJS | idem | ticket séparé |
| media-service | NestJS | idem | ticket séparé |
| scheduling-service | NestJS | idem | ticket séparé |
| messaging-service | Elixir/Phoenix | `opentelemetry_exporter` + `opentelemetry_phoenix` | ticket séparé |
| notification-service | Elixir/Phoenix | idem | ticket séparé |
| calls-service | Elixir/Phoenix | idem | ticket séparé |

Pattern NestJS (à appliquer dans `main.ts` avant `NestFactory.create`) :

```ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

if (process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
  const sdk = new NodeSDK({
    serviceName: process.env.OTEL_SERVICE_NAME,
    instrumentations: [getNodeAutoInstrumentations()],
  });
  sdk.start();
}
```

Pattern Elixir (dans `application.ex` ou `config/runtime.exs`) :

```elixir
if System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT") do
  :ok = :opentelemetry.register_tracer(:whispr_messaging, "1.0.0")
end
```

## Validation

```bash
helm template helm/opentelemetry-collector
helm template helm/tempo
kubectl apply --dry-run=client -f argocd/applications/monitoring/opentelemetry-collector.yaml
kubectl apply --dry-run=client -f argocd/applications/monitoring/tempo.yaml
```

Une fois synchronisé dans le cluster, vérifier dans Grafana que la
datasource Tempo est disponible (Explore → Tempo). Les traces apparaîtront
dès que le premier service est instrumenté.
