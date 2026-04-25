# Construction des images

## Multi-stage build

```
┌────────────────┐
│  Stage 1:      │
│  Builder       │
│  npm install   │
│  npm run build │
└───────┬────────┘
        │
┌───────▼────────┐
│  Stage 2:      │
│  Runtime       │
│  node:22-alpine│
│  (image finale)│
└────────────────┘
```

L'image finale ne contient que le code compilé et les dépendances de production.
