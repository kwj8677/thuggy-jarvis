#!/usr/bin/env bash
set -euo pipefail

QUERY="${1:-ai agent training}"
OUT_DIR="${2:-/home/humil/.openclaw/workspace/training-runs}"
TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$OUT_DIR/$TS"
mkdir -p "$RUN_DIR"

log() { echo "[$(date +%H:%M:%S)] $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1"; exit 2; }
}

require_cmd agent-browser

log "Step 1/8: open search page"
agent-browser open "https://duckduckgo.com" >"$RUN_DIR/01-open.txt"

log "Step 2/8: wait for input"
agent-browser wait "input[name='q']" >"$RUN_DIR/02-wait-input.txt"

log "Step 3/8: type query"
agent-browser fill "input[name='q']" "$QUERY" >"$RUN_DIR/03-fill.txt"

log "Step 4/8: submit"
agent-browser press Enter >"$RUN_DIR/04-enter.txt"

log "Step 5/8: wait results"
agent-browser wait 2500 >"$RUN_DIR/05-wait-results.txt"

log "Step 6/8: capture state"
agent-browser get title >"$RUN_DIR/title.txt"
agent-browser get url >"$RUN_DIR/url.txt"
agent-browser snapshot >"$RUN_DIR/snapshot.txt" || true

TITLE="$(tr -d '\r' < "$RUN_DIR/title.txt" | xargs)"
URL="$(tr -d '\r' < "$RUN_DIR/url.txt" | xargs)"

log "Step 7/8: verify state change"
PASS=true
if [[ "$TITLE" != *"DuckDuckGo"* ]]; then
  echo "TITLE_CHECK_FAIL: $TITLE" >"$RUN_DIR/assertions.txt"
  PASS=false
fi
if [[ "$URL" != *"q="* ]]; then
  echo "URL_CHECK_FAIL: $URL" >>"$RUN_DIR/assertions.txt"
  PASS=false
fi

log "Step 8/8: screenshot + report"
agent-browser screenshot "$RUN_DIR/result.png" >"$RUN_DIR/08-screenshot.txt"

cat >"$RUN_DIR/report.json" <<JSON
{
  "query": $(printf '%s' "$QUERY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "title": $(printf '%s' "$TITLE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "url": $(printf '%s' "$URL" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "pass": $PASS,
  "runDir": $(printf '%s' "$RUN_DIR" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
}
JSON

if [[ "$PASS" == true ]]; then
  log "PASS: training run succeeded"
  echo "$RUN_DIR"
else
  log "FAIL: assertions failed (see $RUN_DIR/assertions.txt)"
  echo "$RUN_DIR"
  exit 1
fi
