#!/usr/bin/env bash
set -euo pipefail

# Stable virtualized runner for Windows UIA stage batches
# Default mode is DRY_RUN to avoid accidental API/UI call bursts.

STAGE="${1:-L3}"
RUNS="${RUNS:-10}"

# Optional profile-driven config (env overrides profile)
PROFILE_JSON="${PROFILE_JSON:-/home/humil/.openclaw/workspace/ops/instant-exec-prompt.json}"

MAX_RETRY="${MAX_RETRY:-}"
COOLDOWN_SEC="${COOLDOWN_SEC:-}"
DRY_RUN="${DRY_RUN:-1}"                 # 1=dry-run, 0=execute
CIRCUIT_BREAK_FAILS="${CIRCUIT_BREAK_FAILS:-}"
STAGE_TIMEOUT_SEC="${STAGE_TIMEOUT_SEC:-}"
API_CALL_CAP="${API_CALL_CAP:-}"
API_CALL_REGEX="${API_CALL_REGEX:-\[API_CALL\]|openrouter\.ai|api\.openai\.com|generativelanguage\.googleapis\.com}"

if [[ -f "$PROFILE_JSON" ]]; then
  read_profile() {
    python3 - <<'PY' "$PROFILE_JSON" "$1"
import json,sys
p,key=sys.argv[1],sys.argv[2]
obj=json.load(open(p))
cur=obj
for part in key.split('.'):
    if isinstance(cur,dict) and part in cur:
        cur=cur[part]
    else:
        cur=''
        break
print(cur if cur is not None else '')
PY
  }

  [[ -z "$MAX_RETRY" ]] && MAX_RETRY="$(read_profile guards.maxRetry)"
  [[ -z "$COOLDOWN_SEC" ]] && COOLDOWN_SEC="$(read_profile guards.cooldownSec)"
  [[ -z "$CIRCUIT_BREAK_FAILS" ]] && CIRCUIT_BREAK_FAILS="$(read_profile guards.circuitBreakConsecutiveFailures)"
  [[ -z "$STAGE_TIMEOUT_SEC" ]] && STAGE_TIMEOUT_SEC="$(read_profile guards.stageTimeoutSec)"
  [[ -z "$API_CALL_CAP" ]] && API_CALL_CAP="$(read_profile guards.apiCallCap)"
fi

# hard defaults
MAX_RETRY="${MAX_RETRY:-1}"
COOLDOWN_SEC="${COOLDOWN_SEC:-30}"
CIRCUIT_BREAK_FAILS="${CIRCUIT_BREAK_FAILS:-3}"
STAGE_TIMEOUT_SEC="${STAGE_TIMEOUT_SEC:-180}"
API_CALL_CAP="${API_CALL_CAP:-50}"

WORKSPACE="/home/humil/.openclaw/workspace"
RUN_STAGE="$WORKSPACE/skills/windows-uia-ops/scripts/run_stage.sh"
UPDATE_MASTER="$WORKSPACE/skills/windows-uia-ops/scripts/update_master.sh"
OUTDIR="$WORKSPACE/reports/uia-batch"
mkdir -p "$OUTDIR"
TS="$(date +%Y%m%d-%H%M%S)"
CORRELATION_ID="uia-${STAGE}-${TS}-$RANDOM"
LOG="$OUTDIR/${TS}-${STAGE}.log"
SUMMARY_JSON="$OUTDIR/${TS}-${STAGE}.summary.json"

lockfile="/tmp/uia_batch_virtualized.lock"
if [[ -e "$lockfile" ]]; then
  echo "LOCKED: another batch seems running: $lockfile"
  exit 2
fi
trap 'rm -f "$lockfile"' EXIT
: > "$lockfile"

echo "[INFO] correlation_id=$CORRELATION_ID stage=$STAGE runs=$RUNS max_retry=$MAX_RETRY cooldown=$COOLDOWN_SEC stage_timeout=$STAGE_TIMEOUT_SEC api_call_cap=$API_CALL_CAP dry_run=$DRY_RUN" | tee -a "$LOG"

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
    echo "[ACTION] run_stage stage=$STAGE run=$i attempt=$attempt" | tee -a "$LOG"

    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[DRY_RUN] bash $RUN_STAGE $STAGE" | tee -a "$LOG"
      run_ok=1
      break
    else
      ATTEMPT_LOG="$(mktemp)"
      set +e
      timeout "${STAGE_TIMEOUT_SEC}s" bash "$RUN_STAGE" "$STAGE" > "$ATTEMPT_LOG" 2>&1
      rc=$?
      set -e

      if [[ $rc -eq 0 ]]; then
        cat "$ATTEMPT_LOG" >> "$LOG"
        rm -f "$ATTEMPT_LOG"
        run_ok=1
        break
      else
        cat "$ATTEMPT_LOG" >> "$LOG"
        if [[ $rc -eq 124 ]]; then
          echo "[TIMEOUT] stage execution exceeded ${STAGE_TIMEOUT_SEC}s" | tee -a "$LOG"
        fi
        # Fatal configuration/mapping errors should not retry.
        if grep -Eiq "Action not found|Invalid config|No such file|Unknown stage|mapping" "$ATTEMPT_LOG"; then
          echo "[FATAL_CONFIG] non-retryable error detected; open circuit immediately" | tee -a "$LOG"
          rm -f "$ATTEMPT_LOG"
          consecutive_failures=$CIRCUIT_BREAK_FAILS
          break
        fi
        rm -f "$ATTEMPT_LOG"
      fi
    fi

    if (( attempt <= MAX_RETRY )); then
      retry_count=$((retry_count+1))
      # Progressive cooldown for repeated transient failures
      current_cooldown=$((COOLDOWN_SEC * attempt))
      echo "[RUN $i] retry after ${current_cooldown}s" | tee -a "$LOG"
      sleep "$current_cooldown"
    fi
  done

  if (( run_ok == 1 )); then
    success=$((success+1))
    consecutive_failures=0
    echo "[RUN $i] PASS" | tee -a "$LOG"
    echo "[STATE_CHANGE] run=$i state=PASS" | tee -a "$LOG"
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

  # Hard API call cap guard (log-pattern based)
  current_api_calls=$(grep -Eic "$API_CALL_REGEX" "$LOG" || true)
  if (( current_api_calls >= API_CALL_CAP )); then
    circuit_break_triggered=1
    echo "[CIRCUIT_BREAK] stop: api_call_cap reached ($current_api_calls/$API_CALL_CAP)" | tee -a "$LOG"
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

# Error bucket (first match wins)
error_bucket="NONE"
if grep -Eiq "Action not found|Invalid config|No such file|Unknown stage|mapping" "$LOG"; then
  error_bucket="CONFIG"
elif grep -Eiq "\[TIMEOUT\]|timed out|TimeoutError|operation timed out" "$LOG"; then
  error_bucket="TRANSIENT_TIMEOUT"
elif grep -Eiq "element not found|not found" "$LOG"; then
  error_bucket="TARGET_UI"
fi

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
  "correlation_id": "$CORRELATION_ID",
  "stage": "$STAGE",
  "runs_requested": $RUNS,
  "runs_executed": $((success+failed)),
  "pass": $success,
  "fail": $failed,
  "total_attempts": $total_attempts,
  "retry_count": $retry_count,
  "circuit_break_triggered": $circuit_break_triggered,
  "meta": {
    "error_bucket": "$error_bucket",
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

echo "[SUMMARY] correlation_id=$CORRELATION_ID pass=$success fail=$failed retries=$retry_count api_calls=$api_calls error_bucket=$error_bucket log=$LOG" | tee -a "$LOG"
echo "[SUMMARY_JSON] $SUMMARY_JSON" | tee -a "$LOG"
