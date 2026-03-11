#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d-%H%M%S)"
OUT="/home/humil/.openclaw/workspace/reports/gateway-health-${TS}.md"
mkdir -p /home/humil/.openclaw/workspace/reports
{
  echo "# Gateway Health Snapshot (${TS})"
  echo
  echo "## 1) gateway status"
  openclaw gateway status || true
  echo
  echo "## 2) port ownership"
  ss -ltnp | grep 18789 || echo "no listener on 18789"
  ss -ltnp | grep 18791 || echo "no listener on 18791"
  echo
  echo "## 3) openclaw processes"
  pgrep -af 'openclaw|openclaw-gateway' || true
  echo
  echo "## 4) recent telegram/gateway errors"
  grep -RIn "Polling stall detected\|sendMessage failed\|sendChatAction failed\|Port 18789 is already in use\|Queued messages while agent was busy" /home/humil/.openclaw/logs /home/humil/.openclaw/log-archive 2>/dev/null | tail -n 80 || true
} > "$OUT"
echo "$OUT"
