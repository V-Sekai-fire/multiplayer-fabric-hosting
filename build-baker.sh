#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_SRC="$REPO_ROOT/multiplayer-fabric-godot"
BAKER_DIR="$REPO_ROOT/multiplayer-fabric-baker/docker/build-project"
CACHE_DIR="${HOME}/.cache/zone-fabric-buildkit"
TAG="multiplayer-fabric-baker:local"

docker buildx build \
  --build-context "godot-src=$GODOT_SRC" \
  --file "$BAKER_DIR/Dockerfile" \
  --cache-from "type=local,src=$CACHE_DIR" \
  --cache-to   "type=local,dest=$CACHE_DIR,mode=max" \
  --tag "$TAG" \
  --load \
  "$BAKER_DIR"

echo "Built $TAG"
