---
name: ops-quickcheck
description: Quick operations bundle for OpenClaw environments: run gateway/health checks, verify tmux session availability, and fetch current weather for Seoul. Use when user asks for combined routine checks or quick environment readiness reports.
---

# Ops Quickcheck

Run this sequence:

1. `openclaw status --deep`
2. `openclaw gateway status`
3. Ensure tmux session `ops` exists (`tmux has-session -t ops || tmux new-session -d -s ops`)
4. Fetch weather via `https://wttr.in/Seoul?format=3`

Return concise summary with pass/fail per item.

See `references/checklist.md` for expected outcomes.
