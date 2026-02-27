#!/usr/bin/env bash
set -euo pipefail

PROMPT="${1:-}"
FORMAT="${2:-text}"
if [[ -z "$PROMPT" ]]; then
  echo "Usage: $0 \"<prompt>\" [text|json|stream-json]" >&2
  exit 2
fi

mkdir -p /mnt/c/temp/openclaw-ops
LOG="/mnt/c/temp/openclaw-ops/gemini-task.log"
PS_SCRIPT_WIN=$(wslpath -w /home/humil/.openclaw/workspace/scripts/win-gemini-task.ps1)

pwsh.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$PS_SCRIPT_WIN" -Prompt "$PROMPT" -OutputFormat "$FORMAT" > "$LOG" 2>&1
cat "$LOG"
