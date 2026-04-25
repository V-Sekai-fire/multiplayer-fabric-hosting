#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_SRC="$REPO_ROOT/multiplayer-fabric-godot"
ZONE_CONSOLE_SRC="$REPO_ROOT/multiplayer-fabric-zone-console"
DOCKERFILE="$REPO_ROOT/docker-multiplayer-fabric/Dockerfile.zone-fabric-build"
GIT_URL_DOCKER="https://github.com/V-Sekai-fire/docker-multiplayer-fabric.git"
CACHE_DIR="${HOME}/.cache/zone-fabric-buildkit"
TAG="zone-fabric:local"

docker buildx build \
  --build-context "godot-src=$GODOT_SRC" \
  --build-context "zone-console-src=$ZONE_CONSOLE_SRC" \
  --file "$DOCKERFILE" \
  --cache-from "type=local,src=$CACHE_DIR" \
  --cache-to   "type=local,dest=$CACHE_DIR,mode=max" \
  --tag "$TAG" \
  --load \
  "$REPO_ROOT/multiplayer-fabric-hosting"

echo "Built $TAG"
