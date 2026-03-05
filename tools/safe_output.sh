#!/usr/bin/env bash
# Usage: safe_output.sh "<command>" [max_chars]
set -euo pipefail
CMD=${1:-}
MAX=${2:-4000}
OUT_DIR="/home/humil/.openclaw/workspace/memory/forensics/raw-output"
mkdir -p "$OUT_DIR"
TS=$(date +%Y%m%d-%H%M%S)
RAW="$OUT_DIR/out-$TS.log"

bash -lc "$CMD" > "$RAW" 2>&1 || true
SIZE=$(wc -c < "$RAW")
LINES=$(wc -l < "$RAW")

echo "saved: $RAW"
echo "bytes: $SIZE lines: $LINES"
if [ "$SIZE" -le "$MAX" ]; then
  cat "$RAW"
else
  echo "--- head(20) ---"
  head -n 20 "$RAW"
  echo "--- tail(20) ---"
  tail -n 20 "$RAW"
  echo "--- summary ---"
  grep -Ei "error|fail|timeout|warn" "$RAW" | tail -n 20 || true
fi
