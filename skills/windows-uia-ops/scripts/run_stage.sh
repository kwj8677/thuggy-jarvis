#!/usr/bin/env bash
set -euo pipefail
stage="${1:-}"
if [[ -z "$stage" ]]; then
  echo "usage: run_stage.sh <action.ps1>"
  exit 2
fi
/home/humil/.openclaw/workspace/scripts/fsw "& 'C:\openclaw\run.ps1' -Action 'session_gate.ps1' -TimeoutSec 20; if (\$LASTEXITCODE -ne 0) { exit \$LASTEXITCODE }; & 'C:\openclaw\run.ps1' -Action '$stage' -TimeoutSec 120"
