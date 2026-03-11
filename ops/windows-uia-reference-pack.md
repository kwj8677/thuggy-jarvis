# Windows UIA Reference Pack (Stable)

이 문서는 Windows 자동화 안정화에 직접 참고한 외부 레퍼런스를 고정해 둔 목록이다.

## Reference tiers

### Tier 1 — 운영용(즉시 적용)
- FlaUI core: https://github.com/FlaUI/FlaUI
- FlaUI searching patterns: https://github.com/FlaUI/FlaUI/wiki/Searching
- FlaUI retry: https://github.com/FlaUI/FlaUI/wiki/Retry
- FlaUInspect (UIA inspect tool): https://github.com/FlaUI/FlaUInspect
- UIA-v2 (AHK): https://github.com/Descolada/UIA-v2
- UIAutomation (AHK): https://github.com/Descolada/UIAutomation
- pywinauto timings: https://github.com/vsajip/pywinauto/blob/master/pywinauto/timings.py
- Polly resilience: https://github.com/App-vNext/Polly
- Polly samples: https://github.com/App-vNext/Polly-Samples

### Tier 2 — 심화용(고도화 때 참고)
- OpenTelemetry log correlation (.NET): https://github.com/open-telemetry/opentelemetry-dotnet/blob/main/docs/logs/correlation/README.md
- Microsoft Engineering Playbook: https://github.com/microsoft/code-with-engineering-playbook
- SRE checklist: https://github.com/bregman-arie/sre-checklist

## Extracted patterns to apply
1. UIA-first selector hierarchy (`AutomationId` > `AutomationId+ControlType` > `Name+ControlType`)
2. State-based success verification (before/after evidence)
3. Centralized timeout/retry defaults
4. Circuit-breaker + error-bucketed retry policy
5. Correlation-id based logging for traceability

## Usage rule
- 레퍼런스는 "코드 그대로 도입"이 아니라 "패턴만 채택"한다.
- 우리 환경(WSL+Windows bridge)에 맞춰 안전 가드(락/쿨다운/상한)를 먼저 붙인다.

## Applied update map (2026-03-11)

### Priority A (already applied)
1. Stage alias + stable stage mapping
   - Applied in: `skills/windows-uia-ops/scripts/run_stage.sh`
   - Mapping: `L1..L5` -> concrete `*.ps1` actions
2. Circuit-breaker hardening (non-retryable config errors)
   - Applied in: `scripts/uia_batch_virtualized.sh`
   - Rule: config/mapping errors open circuit immediately
3. Timeout + API cap guard
   - Applied in: `scripts/uia_batch_virtualized.sh`
   - Keys: `STAGE_TIMEOUT_SEC`, `API_CALL_CAP`
4. Correlation id + error bucket telemetry
   - Applied in: `scripts/uia_batch_virtualized.sh`
   - Outputs: `[SUMMARY]`, `*.summary.json`
5. API call marker for run-stage
   - Applied in: `skills/windows-uia-ops/scripts/run_stage.sh`
   - Marker: `[API_CALL] windows_action=...`

### Priority B (next apply)
1. Selector enforcement in stage scripts
   - Target: reject Name-only write selectors at runtime
   - Files: `skills/windows-uia-ops/scripts/*.sh|*.ps1`
2. State evidence markers
   - Add `[STATE_CHANGE]` markers for write operations
   - Improve `wasted_step_rate` and false-success detection
3. Timing profile centralization
   - New file: `ops/windows-uia-timing-profile.json`
   - Read by batch/stage scripts (no hardcoded drift)

### Priority C (optional advanced)
1. OpenTelemetry-style trace correlation export
2. Stage-level metrics rollup to weekly report JSON
3. RDP/WebView specialized fallback taxonomy

## Source links by improvement theme
- Selector/search reliability: `FlaUI/FlaUI/wiki/Searching`
- Retry/wait patterns: `FlaUI/FlaUI/wiki/Retry`, `pywinauto/timings.py`
- Circuit-break patterns: `App-vNext/Polly`, `App-vNext/Polly-Samples`
- Trace/log correlation: `opentelemetry-dotnet/docs/logs/correlation`

## Action classification (apply / hold / observe)

### Apply now
- Polly + Polly-Samples retry/fallback/circuit composition
- Playwright retry/flaky handling references (concept level)
- SRE checklist items directly tied to runbook discipline

### Hold (later)
- Full OpenTelemetry distributed trace integration
- Multi-browser expansion beyond Chrome/Edge baseline

### Observe (weekly)
- 429 retry-recovery trend
- operational_score / resilience_score drift
- role-based API count trend (primary/subagent/fallback)
