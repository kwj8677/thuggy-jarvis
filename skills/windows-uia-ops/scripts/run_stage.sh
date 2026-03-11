#!/usr/bin/env bash
set -euo pipefail
stage="${1:-}"
if [[ -z "$stage" ]]; then
  echo "usage: run_stage.sh <stage|action.ps1>"
  exit 2
fi

# Runtime selector guard (global policy)
source /home/humil/.openclaw/workspace/skills/windows-uia-ops/scripts/selector_guard.sh
selector_guard_check "$stage" || exit $?

# Stage alias mapping (stable defaults)
case "$stage" in
  L1|l1) action="win_gui_l1_pipeline_uia.ps1" ;;
  L2|l2) action="explorer_l2_pipeline_uia.ps1" ;;
  L3|l3) action="settings_l3_pipeline_uia.ps1" ;;
  L4|l4) action="chrome_uia_pipeline.ps1" ;;
  L5|l5) action="relay_uia_pipeline.ps1" ;;
  *) action="$stage" ;;
esac

echo "[SELECTOR_POLICY] write-stage requires AutomationId/ControlType (name-only forbidden)"
# API role markers (default role for this pipeline: subagent)
API_ROLE="${API_ROLE:-subagent}"
case "$API_ROLE" in
  primary|subagent|fallback) ;;
  *) API_ROLE="subagent" ;;
esac

echo "[API_CALL][$API_ROLE] windows_action=$action via C:\openclaw\run.ps1"
/home/humil/.openclaw/workspace/scripts/fsw "& 'C:\openclaw\run.ps1' -Action 'session_gate.ps1' -TimeoutSec 20; if (\$LASTEXITCODE -ne 0) { exit \$LASTEXITCODE }; & 'C:\openclaw\run.ps1' -Action '$action' -TimeoutSec 120"
