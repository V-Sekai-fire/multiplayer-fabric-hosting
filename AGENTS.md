# Hub Agent Guide — hub-700a.chibifire.com

This document describes the user-facing features of the V-Sekai hub frontend as observed at `https://hub-700a.chibifire.com/`. It is intended for agents that automate, test, or extend this deployment.

## Infrastructure

| Component | Image / Source | Port |
|---|---|---|
| Caddy (TLS termination + reverse proxy) | `caddy:2.9.1-alpine` | 443 (HTTPS), 80 (HTTP redirect) |
| Uro (Phoenix API backend) | `../multiplayer-fabric-zone-backend` | internal :4000 |
| Next.js frontend | `../multiplayer-fabric-zone-backend/frontend` | internal :3000 |
| CockroachDB | `ghcr.io/v-sekai/cockroach:latest` | 26257 |
| versitygw (S3-compatible storage) | `ghcr.io/versity/versitygw:latest` | 7070 |
| desync (chunk server) | `../multiplayer-fabric-desync` | 9090 |

TLS uses a Cloudflare Origin Certificate (`certs/origin.crt` + `certs/origin.key`). Secrets are in `.env` (gitignored); generate with `./generate-secrets.sh` if missing.

## URL Map

| Path | Description |
|---|---|
| `/` | Home — platform description, about, why Godot Engine |
| `/about` | About page |
| `/download` | Download page (currently "open testing" placeholder) |
| `/login` | Sign in with email/username + password, Discord OAuth, or GitHub OAuth |
| `/sign-up` | Register with display name, username, email, password; Discord or GitHub OAuth |
| `/@:username` | User profile page — avatar, banner, bio, privilege ruleset, follow button |
| `/shards` | Zone/shard listing (API-backed) |
| `/avatars` | Avatar listing (API-backed) |
| `/worlds` | World/map listing (API-backed) |
| `/admin` | Admin status check — renders "You have admin panel access" for admin users |
| `/api/v1/admin` | JSON: `{"status":{"is_admin":"true"}}` |
| `/api/v1/dashboard` | JSON: full user profile + Bearer token for the authenticated session |

## User Features

### Account

- **Register** — display name, username, email, password. OAuth via Discord or GitHub. Cloudflare Turnstile CAPTCHA on the form.
- **Sign in** — email or username + password. Discord and GitHub OAuth shortcuts.
- **Sign out** — top-right button when logged in.
- **User profile** (`/@username`) — profile picture, banner image (random Unsplash fallback), display name, @username, biography, online status, creation date. "Edit profile" and follow buttons visible when authenticated.
- **Privilege ruleset** — per-user flags: `is_admin`, `can_upload_avatars`, `can_upload_maps`, `can_upload_props`.
- **Email notifications** — opt-in flag on the account.

### Content

- **Avatars** — listing and upload (requires `can_upload_avatars` privilege). Stored as content-addressed chunks in versitygw (S3).
- **Worlds / Maps** — listing and upload (requires `can_upload_maps` privilege).
- **Props** — upload (requires `can_upload_props` privilege).
- **Shards** — live zone server listing. Each shard exposes address, port, cert hash, and asset index URL for WebTransport clients.

### Navigation (authenticated sidebar on profile pages)

- Home links (×4 — sidebar navigation items)
- Theme toggle
- Logout

### Admin

- Admin users see a gear icon in the top-right navigation.
- `GET /admin` — confirms admin access in the frontend.
- `GET /api/v1/admin` — JSON admin status check.
- `GET /api/v1/dashboard` — returns full profile + Bearer token; used to obtain a token for API automation.
- No web-based admin CRUD panel exists — all admin operations go through the REST API directly.

## Credentials

Credentials are in `.env` (recovered from running containers if lost):

| Variable | Purpose |
|---|---|
| `ADMIN_PASSWORD` | Password for the `adminuser` account |
| `USER_PASSWORD` | Password for the default non-admin user account |
| `PHOENIX_KEY_BASE` | Phoenix session signing key |
| `JOKEN_SIGNER` | JWT signing key for Bearer tokens |

Admin login: username `adminuser`, password from `ADMIN_PASSWORD` in `.env`.

## API Authentication

POST to `/api/v1/session` (or use `GET /api/v1/dashboard` after browser login) to obtain a Bearer token. Include in subsequent requests as `Authorization: Bearer <token>`.

## Known State

- Download page is a placeholder ("open testing").
- Profile page renders raw JSON of the user object below the profile card — this appears to be a development artifact.
- Sidebar on profile pages shows four identical "Home" links — likely a navigation component stub.
- Cloudflare Turnstile on sign-up shows "For testing only" watermark — test site key is in use (`1x00000000000000000000AA`). Replace `TURNSTILE_SITEKEY` in `.env` for production.
