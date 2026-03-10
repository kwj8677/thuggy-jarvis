# Windows Automation Stable Template (WSL + Windows Bridge)

## Goal
Build macOS-grade reliability for Windows automation using UIA-first architecture with strict guardrails.

## Environment Baseline
- Runtime: WSL2 Ubuntu (OpenClaw)
- Windows execution bridge: `psw "<PowerShell command>"`
- Primary stack: `windows-uia-ops`
- Fallback stack: `windows-control` -> vision automation -> AHK force-run

## Control Strategy (in order)
1. **UIA-first**: element by `AutomationId/Name/ControlType`
2. **Vision fallback**: only when UIA path fails
3. **AHK force path**: last resort for stubborn UI

## Success Criteria (must satisfy)
- Never mark success by click log only.
- Require **state transition evidence** + at least one artifact:
  - UIA report JSON, or
  - browser/tab/snapshot proof, or
  - action meta log

## Hard Guardrails (API + loop safety)
- Single-instance lock per scenario
- Max retry: 1 (hard default)
- Cooldown between retries (>= 30s)
- Element wait timeout: 3000ms (default)
- Max action cap per batch: 10
- Stop on consecutive failures (>=3, circuit-break)
- No fan-out parallel loops for same target
- UIA failure must be classified before fallback

## Execution Loop
1. Run session gate
2. Run one stage only (L2/L3/L4/L5)
3. Verify evidence artifacts
4. Log fallback reason if switched
5. Apply one blocker fix only
6. Re-test

## Preferred Stage Targets
- L2: Explorer pipeline (10-pass target)
- L3: Settings pipeline (10-pass target)
- L4: Chrome/UIA pipeline (10-pass target)
- L5: Relay attach + permission + connection proof

## Minimal Operator Checklist
- [ ] Correct Windows session and privilege level
- [ ] Relay attached and verified
- [ ] Chrome profile fixed to User Data + Default
- [ ] Lock/cooldown/retry caps enabled
- [ ] Evidence file paths recorded

## Anti-Patterns (do not do)
- Infinite retry loops
- Coordinate-only automation as default
- Multi-skill parallel write actions on same app
- Success decision without evidence
- Name-only selector for write actions (forbidden)

## Limitation -> Mitigation Patterns

### L1. UIA-invisible surfaces (WebView/RDP/UAC)
- Limitation: UIA tree cannot see some surfaces.
- Mitigation: `UIA -> OCR -> stop` (never infinite loop).
- Rule: If UIA lookup fails within timeout, classify reason and fallback once.

### L2. OCR misread / coordinate drift
- Limitation: OCR can return wrong text/coords.
- Mitigation: `locate -> verify -> click`.
- Rule: For destructive actions, require one extra verification before click.

### L3. Click happened, state unchanged
- Limitation: click logs are weak signals.
- Mitigation: action must be followed by explicit state assertion.
- Rule: Without state transition proof, mark as failed.

### L4. Runaway retries / API burst
- Limitation: retries can explode usage.
- Mitigation: bounded retry budget + cooldown + circuit-break.
- Rule: stop after retry budget is exhausted.

### L5. Environment drift (UAC/session/display/profile)
- Limitation: same script behaves differently across sessions.
- Mitigation: strict pre-gate and fixed profile/session assumptions.
- Rule: do not execute write actions until session gate passes.

## Two-Phase Execution Pattern (recommended)
1. **Read phase**: snapshot + element discovery only.
2. **Write phase**: one write action + immediate verification.
3. On failure: one blocker fix only, then re-test.

## Quick Start
```bash
# stage run (example)
bash /home/humil/.openclaw/workspace/skills/windows-uia-ops/scripts/run_stage.sh L3

# aggregate/update result
bash /home/humil/.openclaw/workspace/skills/windows-uia-ops/scripts/update_master.sh
```

## Reporting Format
Always report in this order:
1) Double-check
2) Conclusion
3) Cold counterpoint (limits/alternatives)
4) Next action
