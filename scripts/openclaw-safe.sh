#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.openclaw/openclaw.json"
if [[ ! -f "$CFG" ]]; then
  echo "ERR: config not found: $CFG" >&2
  exit 1
fi

TOKEN=$(node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));process.stdout.write(j?.gateway?.auth?.token||'')" "$CFG")
if [[ -z "$TOKEN" ]]; then
  echo "ERR: gateway.auth.token missing in $CFG" >&2
  exit 2
fi

case "${1:-probe}" in
  probe)
    openclaw gateway probe --url ws://127.0.0.1:18789 --token "$TOKEN"
    ;;
  win-probe)
    mkdir -p /mnt/c/temp
    pwsh.exe -NoProfile -NonInteractive -Command "openclaw gateway probe --url ws://127.0.0.1:18789 --token $TOKEN" > /mnt/c/temp/openclaw_win_probe.log 2>&1 || true
    tail -n 80 /mnt/c/temp/openclaw_win_probe.log
    ;;
  win-node)
    mkdir -p /mnt/c/temp
    pwsh.exe -NoProfile -NonInteractive -Command "\$env:OPENCLAW_GATEWAY_TOKEN='$TOKEN'; openclaw node run --host 127.0.0.1 --port 18789" > /mnt/c/temp/openclaw_win_node.log 2>&1 || true
    tail -n 80 /mnt/c/temp/openclaw_win_node.log
    ;;
  *)
    echo "Usage: $0 [probe|win-probe|win-node]" >&2
    exit 3
    ;;
esac
