#!/usr/bin/env bash
# qa.sh — run all Playwright tests against the local multiplayer-fabric stack.
#
# Prerequisites:
#   docker compose up -d          (stack running)
#   gescons target=template_debug (web export built in multiplayer-fabric-godot/bin/)
#   pnpm install                  (in multiplayer-fabric-zone-backend/frontend/)
#
# Usage:
#   cd multiplayer-fabric-hosting && ./qa.sh
#   ./qa.sh --headed              # show browser window
#   ./qa.sh transport_peer        # run one test file only
#
# The local stack exposes:
#   http://localhost:8888   Caddy HTTP proxy → uro (no TLS, for QA only)
#   http://localhost:8181   CockroachDB admin UI
#   udp 7443                WebTransport zone server
#
# To test against the live backend instead:
#   API_ORIGIN=https://hub-700a.chibifire.com ./qa.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND="$REPO_ROOT/multiplayer-fabric-zone-backend/frontend"
API_ORIGIN="${API_ORIGIN:-http://localhost:8888}"
FILTER="${1:-}"
HEADED="${HEADED:-}"

cd "$FRONTEND"

if [[ "${1:-}" == "--headed" ]]; then
  HEADED="--headed"
  shift || true
  FILTER="${1:-}"
fi

GODOT_BIN="$REPO_ROOT/multiplayer-fabric-godot/bin/godot.macos.editor.dev.arm64"
WT_LOG="/tmp/wt_server.log"
WT_PID=""

cleanup() {
  [[ -n "$WT_PID" ]] && kill "$WT_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== multiplayer-fabric QA ==="
echo "API_ORIGIN: $API_ORIGIN"
echo "Filter:     ${FILTER:-all tests}"
echo ""

# Verify stack is up
if ! curl -sf "$API_ORIGIN/api/v1/shards" > /dev/null 2>&1; then
  echo "ERROR: local stack not reachable at $API_ORIGIN"
  echo "Run: cd multiplayer-fabric-hosting && docker compose up -d"
  exit 1
fi
echo "Stack: reachable ✓"

# Start Godot WebTransport echo server for wt_browser tests
if [[ -x "$GODOT_BIN" ]]; then
  kill "$(lsof -ti udp:54370)" 2>/dev/null || true
  "$GODOT_BIN" --headless \
    --script "$REPO_ROOT/multiplayer-fabric-godot/modules/http3/demo/wt_server_demo.gd" \
    > "$WT_LOG" 2>&1 &
  WT_PID=$!
  # Wait for the "ready" beacon
  for i in $(seq 1 10); do
    if grep -q "cert_hash" "$WT_LOG" 2>/dev/null; then break; fi
    sleep 1
  done
  if grep -q "cert_hash" "$WT_LOG" 2>/dev/null; then
    echo "WebTransport echo server: ready ✓"
  else
    echo "WebTransport echo server: failed to start (wt_browser tests will fail)"
  fi
else
  echo "WebTransport echo server: skipped (no Godot binary — run gscons first)"
fi
echo ""

export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

API_ORIGIN="$API_ORIGIN" pnpm playwright test \
  --project=chromium \
  --reporter=line \
  ${HEADED} \
  ${FILTER}

echo ""
echo "QA complete."
