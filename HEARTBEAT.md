# HEARTBEAT.md

# Proactive monitoring checklist (cost-aware)

> API 낭비 방지 우선. 상세 규칙은 `ops/api-efficiency-policy.json` 기준.

## Global guards
- Do not run proactive checks more than **3 times/day**.
- If same check ran within **4 hours**, skip it.
- Never use tight polling loops.
- Quiet hours (23:00-08:00 KST): alert only for critical items.

## Allowed checks (throttled)
- Watchdog SoT reference only: `ops/watchdog-sot.md`.
- Memory maintenance (first heartbeat of day only):
  - `scripts/memory_weekly_rollup.py`
  - `scripts/memory_context.py`
  - `scripts/memory_curate.py`
- Memory quality smoke test: `scripts/memory_pipeline.sh` (max once/day).
- Correctness feedback event only: run `scripts/memory_feedback_auto.py --text '<signal>'` when user explicitly says 맞아/틀려.
- Weekly report (Saturday first heartbeat only):
  - `scripts/memory_metrics_report.py`
  - `scripts/memory_weekly_rollup.py --force`
- Model watch: `scripts/check_gpt54.sh` (max once/day).
- Relay attach guard: `scripts/relay_attach_guarded.sh` only when relay-required task queue exists.
- Gmail summary: only high-priority categories (billing/security/secret exposure); ignore noise.

## Reporting rule
- Send concise summary only when there is a net-new, high-priority signal.
- Otherwise respond `HEARTBEAT_OK`.
