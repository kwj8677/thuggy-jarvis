# Agent Orchestration Policy v1

## Goal
품질 유지 + 토큰/부하 최적화를 동시에 달성.

## Core structure
- Main (gpt-codex): Orchestrator only
  - Plan / task-card generation / final synthesis / decision / critical final answer
- Subagents: Worker roles
  - or-free-1: summarize/rewrite/compress/key-point extraction/log cleanup
  - or-free-2: analysis/debugging/reasoning/multi-step technical explanation draft
  - or-free-3: merge outputs + final synthesis draft + decision support
  - or-free-4: audit gate (format/evidence compliance)

## Operating mode
- Default: 3-agent parallel (1~3)
- Complex tasks: 4-agent parallel (+audit)
- Main should not do worker execution; main handles orchestration/final judgment only.
- Spawn timeout must be set per run.

## Control pattern (major-model style)
- Parallel generation: W1~W3 generate candidate outputs in parallel.
- Serial verification: W4(audit) scores format + content gates.
- Deterministic post-check: regex/schema validator runs after audit.
- Auto-repair loop: FAIL/PARTIAL gets exactly 1 regeneration; then fallback to main minimal patch.
- Goal function: maximize speed (parallel) while guaranteeing output contract (deterministic gate).

## Quality gate (hard)
- Output format required (fixed fields / exact line-prefix rules when specified)
- Evidence required (log filenames or concrete artifacts)
- 3-run requirement for validation tasks
- Any missing field => invalid
- Deterministic validator (regex/schema) is the final authority for PASS/FAIL.
- 2 consecutive invalids => demote worker and main handles task directly

## Cost/quality balance
- Main should avoid long drafting; do only orchestration and final judgement.
- Workers use short fixed output template.
- Keep context as task-card (goal/constraints/input/output-format).

## Execution policy (new)
- Single entrypoint for operations: Python runner.
- Adapter split by domain:
  - Web automation: Python + Playwright (primary)
  - Windows system control: Python wrapper -> PowerShell invocation (when needed)
- Web skill/runtime policy (fixed):
  - Primary runtime: local Python + Playwright
  - Secondary helper: `playwright-cli`
  - Blocked: `agent-browser`, `stealth-browser` (cost/risk)
- Web run mode policy:
  - headless default for search/research/extraction
  - headful for UI interaction/debugging/complex workflows
- High-risk action gate:
  - payment/transfer/external-send require explicit final user confirmation before execution
- Do not keep Python in permanent admin mode.
  - Default: standard user
  - Elevation: only for allowlisted high-risk operations

## Final report format
- 더블체크 → 결론 → 냉정한 반론 → 다음 액션
- Must include final status line:
  - [FINAL] 상태: SUCCESS|FAIL|IN_PROGRESS | 원인: ... | 다음액션: ...
