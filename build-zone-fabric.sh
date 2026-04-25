#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_SRC="$REPO_ROOT/multiplayer-fabric-godot"
ZONE_CONSOLE_SRC="$REPO_ROOT/multiplayer-fabric-zone-console"
DOCKERFILE="$GODOT_SRC/.github/docker/Dockerfile.zone-fabric-build"
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
