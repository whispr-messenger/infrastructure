# Rolling Updates

## Stratégie par défaut

```
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Pod v1  │  │ Pod v1  │  │ Pod v1  │
└─────────┘  └─────────┘  └─────────┘
     │
     ▼ nouveau pod v2 démarre
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Pod v2  │  │ Pod v1  │  │ Pod v1  │
└─────────┘  └─────────┘  └─────────┘
                  │
                  ▼ ancien pod v1 arrêté
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Pod v2  │  │ Pod v2  │  │ Pod v1  │
└─────────┘  └─────────┘  └─────────┘
                               │
                               ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Pod v2  │  │ Pod v2  │  │ Pod v2  │
└─────────┘  └─────────┘  └─────────┘
```

Zero downtime grâce au rolling update.
