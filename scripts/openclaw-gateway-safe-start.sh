#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-18789}"

is_listening() {
  ss -ltnp 2>/dev/null | grep -q ":${PORT}"
}

is_gateway_proc() {
  pgrep -af "openclaw-gateway|index.js gateway|openclaw gateway" >/dev/null 2>&1
}

if is_listening && is_gateway_proc; then
  echo "GATEWAY_ALREADY_RUNNING port=${PORT}"
  exit 0
fi

openclaw gateway start >/dev/null
sleep 1

if is_listening; then
  echo "GATEWAY_STARTED port=${PORT}"
  exit 0
fi

echo "GATEWAY_START_FAILED port=${PORT}" >&2
exit 1
