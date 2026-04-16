# Whispr Mobile — Preprod API Migration Guide

**Target preprod:** `https://whispr.devzeyu.com`
**Ticket:** WHISPR-912
**Date:** 2026-04-16

This document tells the mobile app how to repoint its API configuration to the new preprod cluster (`devzeyu`). Everything is served under a **single domain** with **path-based routing**. No subdomains are used.

---

## 1. Key changes vs. previous preprod (citadel)

| Thing | Old (citadel) | New (devzeyu) |
|-------|---------------|---------------|
| Base URL | `https://api.whispr.roadmvn.com` (or similar) | `https://whispr.devzeyu.com` |
| Routing | subdomain per service | **single vhost, path prefix** |
| TLS | Let's Encrypt | Let's Encrypt (unchanged) |
| JWT issuer | `https://auth.whispr.roadmvn.com` | `https://auth.whispr.roadmvn.com` (**unchanged**, same key pair) |
| WebSocket | `wss://.../socket` | `wss://whispr.devzeyu.com/messaging/socket` |
| Image registry | `ghcr.io/whispr-messenger/*` | **same images** (bot builds once, both clusters consume) |

**Important:** the JWT issuer claim stays `https://auth.whispr.roadmvn.com` even in devzeyu preprod, because both clusters sign with the same key. **Do not change JWT verification logic.**

---

## 2. New base URLs per service

Set these in your mobile app's config (`.env`, constants file, etc.):

```
AUTH_BASE_URL         = https://whispr.devzeyu.com/auth
USER_BASE_URL         = https://whispr.devzeyu.com/user
MEDIA_BASE_URL        = https://whispr.devzeyu.com/media
MESSAGING_BASE_URL    = https://whispr.devzeyu.com/messaging
SCHEDULING_BASE_URL   = https://whispr.devzeyu.com/scheduling
NOTIFICATION_BASE_URL = (NOT DEPLOYED on devzeyu preprod — see §8)

WEBSOCKET_URL         = wss://whispr.devzeyu.com/messaging/socket
JWKS_URL              = https://whispr.devzeyu.com/auth/.well-known/jwks.json
```

**Root/single base** (if the app uses one variable):
```
API_BASE = https://whispr.devzeyu.com
```
and prefix each service's path manually.

---

## 3. Full endpoint map

All endpoints are accessible over HTTPS. Paths preserve the service prefix **except** where noted.

### 3.1 auth-service — prefix `/auth/v1`

| Method | Path | Auth |
|--------|------|------|
| GET    | `/auth/v1/health` | none |
| GET    | `/auth/v1/health/ready` | none |
| GET    | `/auth/v1/health/live` | none |
| GET    | `/auth/.well-known/jwks.json` | none (JWT verification key) |
| POST   | `/auth/v1/verify/register/request` | none |
| POST   | `/auth/v1/verify/register/confirm` | none |
| POST   | `/auth/v1/verify/login/request` | none |
| POST   | `/auth/v1/verify/login/confirm` | none |
| POST   | `/auth/v1/register` | none |
| POST   | `/auth/v1/login` | none |
| POST   | `/auth/v1/logout` | JWT |
| POST   | `/auth/v1/tokens/refresh` | JWT (refresh) |
| GET    | `/auth/v1/device` | JWT |
| DELETE | `/auth/v1/device/{deviceId}` | JWT |
| POST   | `/auth/v1/qr-code/challenge/{deviceId}` | JWT |
| POST   | `/auth/v1/qr-code/scan` | JWT |
| POST   | `/auth/v1/2fa/setup`, `/enable`, `/verify`, `/disable`, `/backup-codes` | JWT |
| GET    | `/auth/v1/2fa/status` | JWT |
| GET/POST/DELETE | `/auth/v1/signal/keys/...` | JWT (full Signal key management) |

Swagger UI: `https://whispr.devzeyu.com/auth/swagger`
OpenAPI JSON: `https://whispr.devzeyu.com/auth/swagger-json`

### 3.2 user-service — prefix `/user/v1`

| Method | Path | Auth |
|--------|------|------|
| GET    | `/user/v1/health` | none |
| POST   | `/user/v1/account/bootstrap` | JWT |
| PATCH  | `/user/v1/account/{id}/last-seen` \| `/deactivate` \| `/activate` | JWT |
| DELETE | `/user/v1/account/{id}` | JWT |
| GET/PATCH | `/user/v1/profile/{id}` | JWT |
| GET    | `/user/v1/search/phone` \| `/username` \| `/name` | JWT |
| POST   | `/user/v1/search/phone/batch` | JWT |
| GET/PATCH | `/user/v1/privacy` | JWT |
| GET/POST/PATCH/DELETE | `/user/v1/contacts[/{contactId}]` | JWT |
| GET/POST | `/user/v1/contact-requests` | JWT |
| PATCH  | `/user/v1/contact-requests/{id}/accept` \| `/reject` | JWT |
| DELETE | `/user/v1/contact-requests/{id}` | JWT |
| GET/POST/DELETE | `/user/v1/blocked-users[/{id}]` | JWT |
| GET/POST/PATCH/DELETE | `/user/v1/groups[/{id}]` | JWT |
| GET    | `/user/v1/roles/me` | JWT |
| PUT    | `/user/v1/roles/{userId}` | JWT (admin) |
| GET/POST | `/user/v1/sanctions` | JWT |
| GET    | `/user/v1/sanctions/{stats,me,{id}}` | JWT |
| PUT    | `/user/v1/sanctions/{id}/lift` | JWT (admin) |

Swagger UI: `https://whispr.devzeyu.com/user/swagger`

### 3.3 media-service — prefix `/media/v1`

| Method | Path | Auth |
|--------|------|------|
| GET    | `/media/v1/health` | none |
| POST   | `/media/v1/upload` | JWT |
| GET    | `/media/v1/quota` | JWT |
| GET    | `/media/v1/my-media` | JWT |
| GET/DELETE | `/media/v1/{id}` | JWT |
| GET    | `/media/v1/{id}/blob` | JWT (download) |
| GET    | `/media/v1/{id}/thumbnail` | JWT |

Max upload size: 50 MB (nginx `client_max_body_size`).
Swagger UI: `https://whispr.devzeyu.com/media/swagger`

### 3.4 messaging-service — prefix `/messaging/api/v1` ⚠️

**Double prefix** (`/messaging` + `/api/v1`) — this is Phoenix's basePath. The service is Elixir/Phoenix.

| Method | Path | Auth |
|--------|------|------|
| GET    | `/messaging/api/v1/health/live` \| `/health/ready` \| `/health/detailed` | none |
| GET/PUT/DELETE | `/messaging/api/v1/conversations/{id}` | JWT |
| GET    | `/messaging/api/v1/conversations/search` | JWT |
| GET/PUT | `/messaging/api/v1/conversations/{id}/settings` | JWT |
| POST/DELETE | `/messaging/api/v1/conversations/{id}/archive` \| `/pin` | JWT |
| POST   | `/messaging/api/v1/conversations/{id}/members` | JWT |
| POST/GET | `/messaging/api/v1/conversations/{id}/sanctions` | JWT |
| GET/PUT/DELETE | `/messaging/api/v1/messages/{id}` | JWT |
| POST/GET/DELETE | `/messaging/api/v1/messages/scheduled[/{id}]` | JWT |
| POST   | `/messaging/api/v1/messages/drafts` | JWT |
| GET    | `/messaging/api/v1/conversations/{id}/drafts` | JWT |
| DELETE | `/messaging/api/v1/messages/drafts/{id}` | JWT |
| POST   | `/messaging/api/v1/attachments/upload` | JWT |
| GET/DELETE | `/messaging/api/v1/attachments/{id}` | JWT |
| GET    | `/messaging/api/v1/attachments/{id}/download` | JWT |
| POST/GET | `/messaging/api/v1/reports` | JWT |
| GET    | `/messaging/api/v1/reports/{stats,queue,{id}}` | JWT |
| PUT    | `/messaging/api/v1/reports/{id}/resolve` | JWT |
| GET    | `/messaging/api/v1/reports/analytics/{dashboard,trends,categories,resolution,top-reported}` | JWT |

**WebSocket**: `wss://whispr.devzeyu.com/messaging/socket` (Phoenix Channels)

OpenAPI JSON: `https://whispr.devzeyu.com/messaging/swagger.json`

### 3.5 scheduling-service — prefix `/scheduling` (stripped internally)

Elixir service. Traefik strips `/scheduling` before forwarding, so service sees root paths.

| Method | Path | Auth |
|--------|------|------|
| GET    | `/scheduling/health` | none |
| GET    | `/scheduling/health/ready` | none |

HTTP surface is minimal — most of scheduling-service operates via gRPC (internal, not exposed externally). Swagger: `https://whispr.devzeyu.com/scheduling/swagger`.

### 3.6 notification-service — **NOT DEPLOYED** ⚠️

The image tag `ghcr.io/whispr-messenger/notification-service:sha-841fdc3` referenced on the shared `deploy/preprod` manifest does not exist on GHCR. This is a pre-existing bug inherited from the citadel deployment.

Mobile app should **gracefully handle missing notification service**: disable push-registration calls, or fall back to polling via user/messaging services. Any call to `https://whispr.devzeyu.com/notification/*` will fail (503 / 404).

---

## 4. Authentication

### Login flow
1. `POST /auth/v1/verify/login/request` with `{ "phoneNumber": "+1xxx..." }`
   → sends SMS code. **Preprod devzeyu has no Twilio provider**, so SMS will NOT be delivered. Use a pre-seeded test account or call the confirm endpoint directly if the service has a preprod backdoor.
2. `POST /auth/v1/verify/login/confirm` with `{ "phoneNumber": "+1xxx...", "code": "123456" }`
   → returns JWT access + refresh tokens.
3. Send `Authorization: Bearer <accessToken>` on all protected calls.

### Token refresh
`POST /auth/v1/tokens/refresh` with `{ "refreshToken": "..." }`

### JWT details
- `iss`: `https://auth.whispr.roadmvn.com` (legacy, shared with citadel)
- `aud`: `whispr-api`
- Algorithm: `ES256`
- Public key endpoint: `https://whispr.devzeyu.com/auth/.well-known/jwks.json`

### Preprod-only: DEMO MODE enabled ⭐

Because preprod-devzeyu has no real Twilio, the auth-service runs with `DEMO_MODE=true`. The verification code is **returned in the HTTP response body** — no SMS needed.

```json
POST /auth/v1/verify/register/request
Body:     { "phoneNumber": "+33612345678" }
Response: { "verificationId": "uuid...", "code": "944826" }

POST /auth/v1/verify/login/request      (same behaviour)
```

Mobile-side preprod build should read `code` from the response and autofill (or display) it. In prod, the response will only contain `verificationId` (code stays secret, delivered via SMS).

**Phone number format**: must be E.164 (international with `+`). Examples: `+33612345678`, `+8613800138000`. Fake prefixes like `+15555550100` (US-reserved fictional range) are rejected with 400 "Invalid phone number".

### Code in-response detection

A simple client-side check:
```ts
const resp = await fetch(`${API.auth}/v1/verify/register/request`, { ... });
const json = await resp.json();
if (json.code) {
  // preprod-devzeyu : verification code returned directly
  autofillCode(json.code);
} else {
  // production: wait for user to enter the code from SMS
  promptUserForCode(json.verificationId);
}
```

---

## 5. CORS

Preflight (`OPTIONS`) is handled at the Traefik ingress level. Permissive policy for preprod:

```
Access-Control-Allow-Origin:      <echoes your Origin if it matches>
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods:     GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
Access-Control-Allow-Headers:     *
Access-Control-Max-Age:           3600
```

**Allowed origins** (regex):
- `https://whispr.devzeyu.com` and `http://whispr.devzeyu.com`
- `http://localhost:*` and `http://127.0.0.1:*` (for web dev, React Native Metro, etc.)
- `http://192.168.*.*:*` and `http://10.*.*.*:*` (for LAN testing from phone)
- `http://10.0.2.2:*` (Android emulator loopback)
- `capacitor://localhost` and `ionic://localhost` (Capacitor/Ionic apps)

If your mobile app uses a native HTTP stack (URLSession, OkHttp, fetch from React Native native layer), **CORS is irrelevant** — the server's CORS headers will be returned but native clients ignore them.

If you run the app in a WebView or web-build, CORS applies. Make sure your dev server runs on an origin that matches the regex above.

### Sending credentials
`credentials: true` is allowed. If your client sends cookies, set `withCredentials: true` (axios) or `credentials: 'include'` (fetch). Tokens sent via `Authorization` header do not need this.

---

## 6. WebSocket

Messaging uses Phoenix Channels over WebSocket.

```
URL:      wss://whispr.devzeyu.com/messaging/socket
Params:   token=<JWT_ACCESS_TOKEN> (as query string or in join payload, depending on client)
Topics:   conversation:<conversationId>, user:<userId>
```

**WebSocket upgrade is already configured** on the host nginx vhost (`Upgrade` / `Connection` headers) and on Traefik — no additional config needed.

Connection test from command line:
```bash
# Should return 101 Switching Protocols on success
curl -v --http1.1 -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: AAAAAAAAAAAAAAAAAAAAAA==" \
  "https://whispr.devzeyu.com/messaging/socket/websocket"
```

---

## 7. File upload (media)

`POST /media/v1/upload`

- `Content-Type: multipart/form-data`
- Field name: consult auth-service / media-service contract (typically `file`)
- Max size: **50 MB** (nginx limit)
- Response body includes a `mediaId` you then reference in messaging messages.

Blob fetch: `GET /media/v1/{id}/blob` returns the binary, streaming.

---

## 8. Service health & availability summary

| Service | Status on devzeyu | Notes |
|---------|-------------------|-------|
| auth | ✅ OK | Twilio stubbed — no real SMS |
| user | ✅ OK | |
| media | ✅ OK | MinIO backend, 20 GiB quota total |
| messaging | ✅ OK | WebSocket works |
| scheduling | ✅ OK | Minimal HTTP, mostly gRPC |
| notification | ❌ Not deployed | Image tag broken upstream, feature disabled |
| moderation | ❌ Not deployed | Explicitly out of scope |
| mobile-web | ❌ Not deployed | Explicitly out of scope |

---

## 9. Testing checklist for mobile

After switching base URLs, verify end-to-end:

- [ ] App reads new `API_BASE = https://whispr.devzeyu.com`
- [ ] JWKS fetch succeeds → JWT validation works client-side if you verify
- [ ] Registration / login flow reaches `/verify/login/request` without network error (SMS will fail silently — use backdoor code or seeded user)
- [ ] Authenticated request returns 200 (e.g. `GET /user/v1/roles/me`)
- [ ] Profile fetch works: `GET /user/v1/profile/{myId}`
- [ ] Contact list: `GET /user/v1/contacts`
- [ ] Messaging WebSocket opens and stays connected
- [ ] Send a text message via WS / REST
- [ ] Upload a small image: `POST /media/v1/upload` → receive mediaId
- [ ] Attach mediaId in messaging: `POST /messaging/api/v1/attachments/upload` or send message with attachment reference
- [ ] Push notifications **expected to fail gracefully** (notification-service not deployed)

---

## 10. Sample code snippets

### TypeScript / React Native
```ts
export const API = {
  base: 'https://whispr.devzeyu.com',
  auth: 'https://whispr.devzeyu.com/auth',
  user: 'https://whispr.devzeyu.com/user',
  media: 'https://whispr.devzeyu.com/media',
  messaging: 'https://whispr.devzeyu.com/messaging',  // note: append /api/v1 for endpoints
  scheduling: 'https://whispr.devzeyu.com/scheduling',
  notification: null, // disabled on preprod-devzeyu
  wsUrl: 'wss://whispr.devzeyu.com/messaging/socket',
  jwksUrl: 'https://whispr.devzeyu.com/auth/.well-known/jwks.json',
};

// Example
await fetch(`${API.auth}/v1/verify/login/request`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ phoneNumber: '+15555550100' }),
});

// Messaging (note the /api/v1 in the path)
await fetch(`${API.messaging}/api/v1/conversations/search?q=hello`, {
  headers: { Authorization: `Bearer ${accessToken}` },
});
```

### Swift
```swift
enum Whispr {
    static let base = URL(string: "https://whispr.devzeyu.com")!
    static let auth = base.appendingPathComponent("auth")
    static let user = base.appendingPathComponent("user")
    static let media = base.appendingPathComponent("media")
    static let messaging = base.appendingPathComponent("messaging")
    static let scheduling = base.appendingPathComponent("scheduling")
    static let wsUrl = URL(string: "wss://whispr.devzeyu.com/messaging/socket")!
}
```

### Kotlin
```kotlin
object Whispr {
    const val BASE = "https://whispr.devzeyu.com"
    const val AUTH = "$BASE/auth"
    const val USER = "$BASE/user"
    const val MEDIA = "$BASE/media"
    const val MESSAGING = "$BASE/messaging"
    const val MESSAGING_API = "$MESSAGING/api/v1"
    const val SCHEDULING = "$BASE/scheduling"
    const val WS = "wss://whispr.devzeyu.com/messaging/socket"
}
```

---

## 11. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| 503 on all paths | Cluster down | Check `kubectl -n whispr-preprod get pods` |
| 404 on `/messaging/conversations/...` | Forgot `/api/v1/` segment | Use `/messaging/api/v1/conversations/...` |
| 401 | Missing or expired JWT | Call `/auth/v1/tokens/refresh` or re-login |
| CORS error in browser dev tools | Origin not in allow-regex | Use `localhost`, LAN IP, or `whispr.devzeyu.com` |
| WS disconnects immediately | Missing JWT or wrong topic | Include JWT in WS connect params |
| No SMS received | Twilio stubbed | Preprod-only; use backdoor test code |
| Push notifications silent | notification-service not deployed | Expected on devzeyu preprod |

---

## 12. Reverting

If you need to point back to the old preprod (citadel) temporarily, it is still running and listens on its own domain. Only the base URLs above are devzeyu-specific; everything else (JWT keys, DB schemas, service contracts) is identical across both clusters.
