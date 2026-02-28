#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/humil/.openclaw/workspace"
MEM_DIR="$ROOT/memory"
SESS_DIR="$MEM_DIR/sessions"
TODAY="$(date +%F)"
DAILY="$MEM_DIR/$TODAY.md"
CURATED="$ROOT/MEMORY.md"
INBOX="$SESS_DIR/inbox.md"

mkdir -p "$SESS_DIR"
touch "$DAILY" "$INBOX"

# 1) session raw -> daily (최근 24h decision/change/failure 최대 5줄)
TMP="$(mktemp)"
find "$SESS_DIR" -maxdepth 1 -type f -name "*.md" ! -name "README.md" -print0 \
  | xargs -0 -I{} tail -n 50 "{}" 2>/dev/null \
  | grep -E "decision|change|failure|deprecated" \
  | tail -n 5 > "$TMP" || true

if [[ -s "$TMP" ]]; then
  {
    echo ""
    echo "## rollup $(date '+%Y-%m-%d %H:%M:%S %Z')"
    cat "$TMP"
  } >> "$DAILY"
fi

# 2) daily -> curated 후보 출력(자동 반영 대신 제안만)
# 안전성 위해 자동 overwrite/auto-edit 안 함
CANDIDATES="$(mktemp)"
grep -E "decision|deprecated|운영 원칙|선호" "$DAILY" | tail -n 10 > "$CANDIDATES" || true

if [[ -s "$CANDIDATES" ]]; then
  echo "[memory-rollup] curated candidates:"
  cat "$CANDIDATES"
  echo "[memory-rollup] review and append manually to $CURATED"
else
  echo "[memory-rollup] no curated candidates"
fi

rm -f "$TMP" "$CANDIDATES"
echo "[memory-rollup] done"
