#!/usr/bin/env bash
set -euo pipefail

BASE="/home/humil/.openclaw/workspace/scripts"

"$BASE/memory_context.py" --query "운영 규칙 안정성 선호 진행중 작업" --top-k 6 --min-score 0.45
"$BASE/memory_compose.py" --max-total 4
"$BASE/memory_curate.py" --dry-run
"$BASE/memory_metrics_report.py"

echo "MEMORY_PIPELINE_OK"
