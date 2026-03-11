#!/usr/bin/env bash
set -euo pipefail

# Global selector guard for write stages
# Contract: SELECTOR_HINT format examples:
# - automationid:SaveBtn
# - controltype:Button
# - name-only:Save

selector_guard_check() {
  local stage="$1"
  local hint="${SELECTOR_HINT:-}"
  if [[ -z "$hint" ]]; then
    return 0
  fi

  if [[ "$hint" =~ ^name-only: ]]; then
    if [[ "$stage" =~ ^(L3|l3|L4|l4|L5|l5|settings_l3_pipeline_uia\.ps1|chrome_uia_pipeline\.ps1|relay_uia_pipeline\.ps1)$ ]]; then
      echo "[FATAL_SELECTOR] Name-only selector is forbidden for write stages: $stage"
      return 4
    fi
  fi

  return 0
}
