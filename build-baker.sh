#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_SRC="$REPO_ROOT/multiplayer-fabric-godot"
BAKER_DIR="$REPO_ROOT/multiplayer-fabric-baker/docker/build-project"
GIT_URL_DOCKER="https://github.com/V-Sekai-fire/docker-multiplayer-fabric.git"
DOCKERFILE="$REPO_ROOT/docker-multiplayer-fabric/Dockerfile.baker"
CACHE_DIR="${HOME}/.cache/zone-fabric-buildkit"
TAG="multiplayer-fabric-baker:local"

docker buildx build \
  --build-context "godot-src=$GODOT_SRC" \
  --file "$DOCKERFILE" \
  --cache-from "type=local,src=$CACHE_DIR" \
  --cache-to   "type=local,dest=$CACHE_DIR,mode=max" \
  --tag "$TAG" \
  --load \
  "$BAKER_DIR"

echo "Built $TAG"
