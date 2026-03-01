# First Principles GUI Automation (OpenClaw)

## Objective
- Goal is **not** “click succeeded”.
- Goal is **reproducible state transition** with verifiable evidence.

## Non-negotiable Constraints
1. **Session**: Must run in user interactive session for visible GUI.
2. **Focus**: Input/click reliability depends on active window and focus state.
3. **Selector Stability**: DOM/ref/UIA identifiers are more stable than pixels.
4. **Verifiability**: Success must be judged by state signals, not assumptions.

## Priority of Control Paths
1. Browser GUI: **CDP/ref-based control** (agent-browser/Relay)
2. Windows app GUI: **PowerShell UIA** first
3. Fallback only: **AHK coordinates/image**

Rule: `structure-based > semantic-based > pixel-based`

## Success Criteria (3-gate)
Every action is successful only if all pass:
1. **Action Executed**: click/type submitted without runtime error
2. **State Changed**: URL/text/count/button-state changed as expected
3. **Evidence Logged**: snapshot/screenshot/log captured

If any gate fails, outcome = fail.

## Architecture
- **Executor**: `psw` + `C:\openclaw\run.ps1`
- **Planner/Orchestrator**: Python (branching, retries, normalization)
- **Drivers**:
  - Browser: CDP/Relay
  - WinApp: UIA
  - Fallback: AHK
- **Verifier**: explicit state checks (count/toast/list existence)
- **Recovery**: retry/backoff + path downgrade (CDP -> UIA -> AHK)

## Preflight (required)
Before GUI flow starts:
- Interactive session confirmed
- Required permissions/policies confirmed
- Target window handle/active state confirmed
- Auth/session validity confirmed

## Reliability KPI
- Optimize for **10 consecutive successful runs**, not one-off success.

## Failure Taxonomy
Classify every failure into:
- session isolation
- focus/visibility
- policy block
- auth expiration/challenge
- selector drift
- network/timing

Each class must map to a deterministic recovery action.

## Operational Policy
- Never mark success from a click alone.
- Never rely on memory for secret/auth context; source-of-truth files only.
- Keep high-risk actions behind approval gates.
