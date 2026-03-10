# Windows UIA Improvement Checklist (Stable-first)

## Scope
Apply proven reliability patterns from community references (FlaUI/UIA/pywinauto resilience patterns) to our Windows UIA pipeline.

## A. Selector Strategy Hardening
- [ ] Use selector priority:
  1) `AutomationId`
  2) `AutomationId + ControlType`
  3) `Name + ControlType`
- [ ] Avoid Name-only selectors for write actions.
- [ ] Record selector miss reason codes:
  - `NOT_FOUND`
  - `UNSTABLE_ID`
  - `UNSUPPORTED_PROPERTY`

## B. Timing Centralization
- [ ] Move timing defaults to one source (`ops/windows-automation-stable-template.md` + script vars).
- [ ] Baseline values:
  - `elementWaitTimeoutMs=3000`
  - `maxRetry=1`
  - `cooldownSec=30`
- [ ] Remove ad-hoc per-script timeout literals where possible.

## C. State-Based Success Enforcement
- [ ] For write action, require `before/after` verification.
- [ ] Success requires state transition evidence.
- [ ] If evidence < 2 artifacts, mark as FAIL.

## D. Resilience Guards
- [ ] Single-instance lock per scenario.
- [ ] Retry budget exhausted => stop.
- [ ] Consecutive fail >= 3 => circuit break stop.
- [ ] No fan-out parallel writes to same target.

## E. Fallback Policy
- [ ] UIA failure must be classified before fallback.
- [ ] Allowed path: `UIA -> OCR/Vision -> stop`.
- [ ] Coordinate-only is never default path.

## F. Reporting Standard
Always output in this order:
1. Double-check
2. Conclusion
3. Cold counterpoint (limits/alternatives)
4. Next action

## Diff Plan (before/after)
- Before: selector/timing/success conditions vary by script.
- After: centralized timing, selector hierarchy, evidence-gated success, hard retry/circuit guard.

## Risk/Impact
- Positive: lower loop risk, lower false-success rate, lower API waste.
- Tradeoff: slightly slower fail-fast due to verification steps.

## Rollback
- Revert last commit touching scripts and template.
- Keep artifacts/logs for postmortem.
