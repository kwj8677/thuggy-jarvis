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
- Max retry: 1~2
- Cooldown between retries (>= 30s)
- Max run cap per batch
- Stop on consecutive failures (circuit-break)
- No fan-out parallel loops for same target

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
