# Communication gRPC

## Schéma global

```
┌──────────────┐  gRPC  ┌───────────────┐  gRPC  ┌────────────────┐
│ Scheduling   │◄──────▶│  Messaging    │◄──────▶│ Notification   │
│ Service      │        │  Service      │        │ Service        │
│ (50051)      │        │  (50052)      │        │ (50053)        │
└──────────────┘        └───────┬───────┘        └────────────────┘
                                │
                          gRPC  │
                                │
                        ┌───────▼───────┐
                        │  Moderation   │
                        │  Service      │
                        │  (50052)      │
                        └───────────────┘
```

Toutes les communications gRPC passent par les sidecars Envoy (mTLS automatique).
