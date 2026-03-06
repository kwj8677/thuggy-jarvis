# HEARTBEAT.md

# Proactive monitoring checklist (user-approved)

- Run `scripts/gateway_guard.py --recover-on-alert --notify-cmd '/home/humil/.openclaw/workspace/scripts/send_guard_email.py'` each heartbeat.
- Run `scripts/memory_weekly_rollup.py` once per day (first heartbeat only) to keep weekly context fresh.
- Run `scripts/memory_context.py` once per day (or after major policy changes) to refresh `/tmp/openclaw/memory-context-latest.json`.
- Run `scripts/memory_curate.py` once per day (first heartbeat only) to prune duplicates/conflicts.
- Run `scripts/memory_preflight_brief.py` before major user-facing reports to keep continuity cues in the response.
- For daily memory quality smoke test, run `scripts/memory_pipeline.sh` once (context→compose→curate(dry-run)→metrics report).
- If user gives explicit correctness signal (e.g., "맞아/틀려"), run `scripts/memory_feedback_auto.py --text '<signal>'` to auto-adjust top recalled item confidence.
- Weekly proactive report (even if user forgets):
  - Every Saturday first heartbeat, run `scripts/memory_metrics_report.py` and `scripts/memory_weekly_rollup.py --force`.
  - Then send a concise push update: hit-rate, re-explain count, wrong-reference count, and next tuning action.
- It auto-rolls old `/tmp/openclaw/openclaw-*.log` files and detects: 429, rate limit, FailoverError, embedded run timeout, gateway timeout.
- It dedupes repeated lines, classifies severity (warn/critical), and on alert auto-recovers gateway then verifies.
- Reporting policy:
  - If `recovery.attempted=true`: always report (what failed, restart result, verify result).
  - If `alert=true` after recovery: immediate high-priority alert + next mitigation.
  - If recovered (`recovery.restart_ok=true` and `recovery.verify_ok=true`): send concise recovery report (cause/time/fix/result).

- Check Gmail (Relay-attached tab) inbox summary:
  - Report only high-priority categories:
    - billing/payment failures
    - security/sign-in alerts
    - secret leak/exposure alerts
  - Ignore promotions/social noise.
  - If new high-priority mail exists, send concise alert with sender + subject + time.
