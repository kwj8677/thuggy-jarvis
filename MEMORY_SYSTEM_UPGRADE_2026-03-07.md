# Memory/Operations Upgrade Summary (2026-03-07)

## Goal
Improve OpenClaw continuity/memory quality to feel closer to GPT app-style long-term coherence while keeping operations stability.

## What was implemented

### 1) Gateway reliability + alerting
- `scripts/gateway_guard.py`
  - Log rolling (`/tmp/openclaw/openclaw-*.log`)
  - Error detection (429/rate-limit/failover/embedded timeout/gateway timeout)
  - Dedupe window
  - Severity classification (`warn`/`critical`)
  - Auto-recovery (`--recover-on-alert`) + verify
  - Forensics snapshot on alert (`/tmp/openclaw/forensics/...`)
- `scripts/send_guard_email.py`
  - Gmail SMTP alert delivery from `secrets/local-secrets.json`

### 2) Structured memory stack (Phase 1~5)
- `memory/profile.json`
  - User preference/operating profile
- `memory/memory_items.jsonl`
  - Structured memory items (`fact|preference|decision|task_state`)
- `scripts/memory_capture.py`
  - Rule-based memory write, duplicate suppression, graph fields (`entity`,`project`,`depends_on`)
- `scripts/memory_recall.py`
  - Scored recall with freshness/confidence/type weighting + min-score gate
  - Graph bonus scoring
- `scripts/memory_curate.py`
  - Dedupe/supersede handling
- `scripts/memory_weekly_rollup.py`
  - Weekly rollup generation + once-per-day gate
- `scripts/memory_context.py`
  - Preflight memory snapshot generation + metric auto-count integration
- `scripts/memory_preflight_brief.py`
  - concise memory cue output for major reports
- `scripts/memory_compose.py`
  - response-composer constraints (type caps + max-total)
- `scripts/memory_feedback.py`
  - confidence update from explicit user feedback
- `scripts/memory_feedback_auto.py`
  - auto-map short signals (e.g., 맞아/틀려) to confidence updates
- `scripts/memory_metrics_update.py`
  - KPI counter updates
- `scripts/memory_metrics_report.py`
  - weekly KPI markdown report
- `scripts/memory_pipeline.sh`
  - smoke pipeline (context→compose→curate→metrics)

### 3) Heartbeat policy updates (`HEARTBEAT.md`)
- Run gateway guard with auto-recovery + email notify
- Daily memory context/curation/pipeline checks
- Weekly proactive metrics report/rollup push even if user forgets

## Current status
- Core scripts compile/run verified
- Recall, compose, feedback, metrics loops tested end-to-end
- Gateway alert pipeline tested (email send OK)

## Remaining recommended tuning
1. Query/weight tuning over 1~2 weeks based on KPI trend
2. Expand recall graph links for project/entity cross-context
3. Add stricter false-positive control for auto-feedback mapping
