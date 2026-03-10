#!/usr/bin/env bash
set -euo pipefail

# Stable virtualized runner for Windows UIA stage batches
# Default mode is DRY_RUN to avoid accidental API/UI call bursts.

STAGE="${1:-L3}"
RUNS="${RUNS:-10}"
MAX_RETRY="${MAX_RETRY:-1}"
COOLDOWN_SEC="${COOLDOWN_SEC:-30}"
DRY_RUN="${DRY_RUN:-1}"                 # 1=dry-run, 0=execute
CIRCUIT_BREAK_FAILS="${CIRCUIT_BREAK_FAILS:-3}"
API_CALL_REGEX="${API_CALL_REGEX:-openrouter\.ai|api\.openai\.com|generativelanguage\.googleapis\.com}"

WORKSPACE="/home/humil/.openclaw/workspace"
RUN_STAGE="$WORKSPACE/skills/windows-uia-ops/scripts/run_stage.sh"
UPDATE_MASTER="$WORKSPACE/skills/windows-uia-ops/scripts/update_master.sh"
OUTDIR="$WORKSPACE/reports/uia-batch"
mkdir -p "$OUTDIR"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$OUTDIR/${TS}-${STAGE}.log"
SUMMARY_JSON="$OUTDIR/${TS}-${STAGE}.summary.json"

lockfile="/tmp/uia_batch_virtualized.lock"
if [[ -e "$lockfile" ]]; then
  echo "LOCKED: another batch seems running: $lockfile"
  exit 2
fi
trap 'rm -f "$lockfile"' EXIT
: > "$lockfile"

echo "[INFO] stage=$STAGE runs=$RUNS max_retry=$MAX_RETRY cooldown=$COOLDOWN_SEC dry_run=$DRY_RUN" | tee -a "$LOG"

success=0
failed=0
total_attempts=0
retry_count=0
consecutive_failures=0
circuit_break_triggered=0

for ((i=1; i<=RUNS; i++)); do
  echo "[RUN $i/$RUNS] start" | tee -a "$LOG"
  attempt=0
  run_ok=0

  while (( attempt <= MAX_RETRY )); do
    attempt=$((attempt+1))
    total_attempts=$((total_attempts+1))
    echo "[RUN $i] attempt=$attempt" | tee -a "$LOG"

    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[DRY_RUN] bash $RUN_STAGE $STAGE" | tee -a "$LOG"
      run_ok=1
      break
    else
      if bash "$RUN_STAGE" "$STAGE" >> "$LOG" 2>&1; then
        run_ok=1
        break
      fi
    fi

    if (( attempt <= MAX_RETRY )); then
      retry_count=$((retry_count+1))
      echo "[RUN $i] retry after ${COOLDOWN_SEC}s" | tee -a "$LOG"
      sleep "$COOLDOWN_SEC"
    fi
  done

  if (( run_ok == 1 )); then
    success=$((success+1))
    consecutive_failures=0
    echo "[RUN $i] PASS" | tee -a "$LOG"
  else
    failed=$((failed+1))
    consecutive_failures=$((consecutive_failures+1))
    echo "[RUN $i] FAIL (retry exhausted)" | tee -a "$LOG"
  fi

  if (( consecutive_failures >= CIRCUIT_BREAK_FAILS )); then
    circuit_break_triggered=1
    echo "[CIRCUIT_BREAK] stop: consecutive_failures=$consecutive_failures" | tee -a "$LOG"
    break
  fi

done

if [[ "$DRY_RUN" == "1" ]]; then
  echo "[DRY_RUN] bash $UPDATE_MASTER" | tee -a "$LOG"
else
  bash "$UPDATE_MASTER" >> "$LOG" 2>&1 || true
fi

# --- Meta analysis (best-effort, log-driven) ---
api_calls=$(grep -Eic "$API_CALL_REGEX" "$LOG" || true)

# If stage logs include [ACTION] lines, count adjacent duplicates.
# Example expected format: [ACTION] click #SaveButton
duplicate_actions=$(awk '
  /^\[ACTION\]/ {
    if (prev == $0) dup++;
    prev = $0;
    total++;
  }
  END { print dup+0 }
' "$LOG")

action_total=$(awk '/^\[ACTION\]/{c++} END{print c+0}' "$LOG")

# If stage logs include [STATE_CHANGE] markers, we can estimate wasted steps.
state_changes=$(awk '/^\[STATE_CHANGE\]/{c++} END{print c+0}' "$LOG")
if (( action_total > 0 )); then
  # crude proxy: actions without explicit state change marker
  wasted_steps=$(( action_total > state_changes ? action_total - state_changes : 0 ))
  wasted_step_rate=$(python3 - <<PY
at=$action_total
ws=$wasted_steps
print(round(ws/at,4) if at else 0)
PY
)
  duplicate_action_rate=$(python3 - <<PY
at=$action_total
da=$duplicate_actions
print(round(da/at,4) if at else 0)
PY
)
else
  wasted_steps=0
  wasted_step_rate=0
  duplicate_action_rate=0
fi

cat > "$SUMMARY_JSON" <<JSON
{
  "stage": "$STAGE",
  "runs_requested": $RUNS,
  "runs_executed": $((success+failed)),
  "pass": $success,
  "fail": $failed,
  "total_attempts": $total_attempts,
  "retry_count": $retry_count,
  "circuit_break_triggered": $circuit_break_triggered,
  "meta": {
    "api_calls_detected": $api_calls,
    "action_total": $action_total,
    "duplicate_actions": $duplicate_actions,
    "duplicate_action_rate": $duplicate_action_rate,
    "state_changes": $state_changes,
    "wasted_steps": $wasted_steps,
    "wasted_step_rate": $wasted_step_rate
  },
  "log": "$LOG"
}
JSON

echo "[SUMMARY] pass=$success fail=$failed retries=$retry_count api_calls=$api_calls log=$LOG" | tee -a "$LOG"
echo "[SUMMARY_JSON] $SUMMARY_JSON" | tee -a "$LOG"
