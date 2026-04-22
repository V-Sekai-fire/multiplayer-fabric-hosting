# multiplayer-fabric-hosting

One-command self-hosted MMOG stack: zone API, WebTransport zone server, and content-addressed asset delivery.

## What this runs

| Service | Role | Port |
|---|---|---|
| `crdb` | CockroachDB — zone-backend database | 26257 (internal) |
| `versitygw` | S3-compatible object store | 7070 (internal) |
| `uro` | Phoenix API — accounts, auth, asset uploads, zone listing | 4000 (internal) |
| `frontend` | Next.js web UI | 3000 (internal) |
| `desync` | CAIBX chunk server — delta-sync zone asset delivery | 9090 (internal), `/chunks/*` via Caddy |
| `zone-backend` | Caddy reverse proxy — TLS termination, routes all HTTP traffic | 80, 443 |
| `zone-server` | Godot zone server — embedded zone instance; additional zones register with Uro independently | 7443/UDP |

## Prerequisites

- Docker and Docker Compose v2
- `openssl` (for secret generation)
- Ports 80, 443 (TCP) and 7443 (UDP) open on your host

## Quickstart

```sh
git clone --recurse-submodules https://github.com/V-Sekai-fire/multiplayer-fabric
cd multiplayer-fabric/multiplayer-fabric-hosting

# Generate random secrets into .env (safe to re-run — skips existing keys)
./generate-secrets.sh

# Start everything
docker compose up -d

# Watch logs
docker compose logs -f
```

The API is available at `http://localhost/api/v1/` once `uro` is healthy (about 30 seconds on first run while CockroachDB initialises).

## Configuration

All tuneable values are in `.env`. The `generate-secrets.sh` script populates the required secrets. To point at a custom domain, set:

```
URL=https://your-domain.example/api/v1/
ROOT_ORIGIN=https://your-domain.example
FRONTEND_URL=https://your-domain.example/
```

Zone servers have multiplicity 0..∞ and register themselves with Uro at startup — no static list is required in `.env`. The embedded zone server starts automatically with `docker compose up -d`. Set `ZONE_HOST` to your domain so the zone server registers its public address with Uro:

```
ZONE_HOST=zone.your-domain.example
ZONE_PORT=7443
```

Replace the `tls` line in `Caddyfile` with `tls your@email.com` to use Let's Encrypt instead of a Cloudflare Origin Certificate.

## Connecting a Godot client

1. Start the stack with `docker compose up -d`.
2. In your Godot project, create a `FabricMMOGTransportPeer` and call `create_client("127.0.0.1", 7443)`.
3. The peer attempts WebTransport first and falls back to WebSocket automatically.
4. On zone entry, the server emits a desync index URL. The client fetches only the asset chunks it does not already have from `https://your-host/chunks/`.

## Zone asset delta-sync

Zone world data is stored as content-addressed chunks in the `zone-chunks` S3 bucket served by versitygw. The desync service exposes those chunks at `/chunks/` via the Caddy proxy. When a player crosses a zone boundary, the zone server sends a `.caibx` index URL; the Godot client runs a desync pull to fetch only the missing chunks.

To pre-populate a zone's chunk store:

```sh
# From outside the container, using the desync CLI
desync make \
  --store s3+http://localhost:7070/zone-chunks \
  --index zone-world.caibx \
  zone-world-dir/
```

## Stopping

```sh
docker compose down          # stop containers, keep volumes
docker compose down -v       # stop and delete all data
```
