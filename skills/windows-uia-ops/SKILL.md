---
name: windows-uia-ops
description: Operate and stabilize Windows GUI automation (OpenClaw+UIA+Relay) with first-principles gates and evidence-based verification. Use for L1~L5 training, relay attach troubleshooting, chrome default-profile enforcement, and naver write/save verification loops.
---

# Windows UIA Ops

Use this skill as the default execution framework for Windows GUI automation.

## Run Order (mandatory)
1. Run `session_gate.ps1`.
2. Run target stage pipeline (L1/L2/L3/L4/L5).
3. Verify state change using evidence artifacts, not click logs.
4. Store outcome in `training-runs/uia-master-dataset.json` via aggregator.

## Hard Rules
- Enforce Chrome profile: `User Data + Default` only.
- Fail fast on gate failure (no forced continuation).
- Use multi-source relay verification: `okByTabs OR okByAttached`.
- Windows priority fallback order:
  1) `windows-control` or `windows-uia-advanced` (UIA first)
  2) `midscene-computer-automation`
  3) `AHK` force-run
- Always log fallback transitions: `Fallback to [skill] because [reason]`.
- Success = state transition + evidence, never "clicked" only.

## Validated Baseline
- 2026-03-02 baseline pass evidence preserved:
  - `settings_l3_pipeline_uia.ps1` pass log: `C:\openclaw\logs\20260302-225440-settings-l3-pipeline-uia.json`
  - `chrome_uia_pipeline.ps1` pass log: `C:\openclaw\logs\20260302-225526-chrome-uia-pipeline.json`
  - `explorer_l2_pipeline_uia.ps1` recovered pass after retry
- 2026-03-03 cross-train baseline:
  - `uia_ahk_cross_train.ps1` CI cycle 10/10 pass (`/tmp/uia_ahk_batch_raw.json`)
- 2026-03-04 aggregated trace dataset:
  - `training-runs/fallback-trace-2026-03-04.json`
  - `training-runs/fallback-trace-2026-03-04.md`
  - Findings: explorer/settings and relay icon targeting are comparatively stable; relay permission + tabs gate remain primary bottlenecks.

## Stage Targets
- L2: explorer pipeline 10-pass target
- L3: settings pipeline 10-pass target
- L4: chrome pipeline 10-pass target
- L5: relay attach/permission + real connection proof

## Evidence Minimum
At least two of:
- UIA report json
- Browser tab/snapshot evidence
- action log/meta report

## Files to use
- `references/ops-checklist.md`
- `references/failure-taxonomy.md`
- `references/continuous-improvement-loop.md`
- `scripts/run_stage.sh`
- `scripts/update_master.sh`
- `scripts/ci_cycle.sh`

## Mandatory operating loop
- Always run the continuous improvement loop after a batch.
- Apply only one blocker fix per cycle, then re-test.
- Update this skill immediately with validated evidence and rule changes.
