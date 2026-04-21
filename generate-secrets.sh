#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# Populate .env with random secrets before the first `docker compose up`.
# Safe to re-run — existing keys are never overwritten.
#
# Usage:
#   cd multiplayer-fabric-hosting
#   ./generate-secrets.sh
#   docker compose up -d

set -e

ENV_FILE="$(dirname "$0")/.env"
touch "$ENV_FILE"

rand32() {
  openssl rand -base64 48 | tr -d '\n/+=' | cut -c1-32
}

rand64() {
  openssl rand -base64 64 | tr -d '\n/+=' | cut -c1-64
}

add_secret() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    echo "  ${key}: already set, skipping"
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
    echo "  ${key}: generated"
  fi
}

echo "Writing secrets to $ENV_FILE ..."
add_secret ADMIN_PASSWORD "$(rand32)"
add_secret USER_PASSWORD  "$(rand32)"
add_secret PHOENIX_KEY_BASE "$(rand64)"
add_secret JOKEN_SIGNER   "$(rand32)"
echo "Done. Run: docker compose up -d"
