#!/usr/bin/env bash
set -euo pipefail
BATCH="${1:-10}"

echo "[1/3] run cross-train batch: $BATCH"
cat <<PS | /home/humil/.openclaw/workspace/scripts/fsw > /tmp/uia_ahk_batch_raw.json
\$rows=@()
for(\$i=1;\$i -le $BATCH;\$i++){
  & 'C:\openclaw\run.ps1' -Action 'uia_ahk_cross_train.ps1' -TimeoutSec 95 | Out-Null
  \$rows += [pscustomobject]@{run=\$i;exitCode=\$LASTEXITCODE}
}
\$rows|ConvertTo-Json -Depth 4
PS

echo "[2/3] aggregate"
python3 /home/humil/.openclaw/workspace/windows-openclaw/actions/uia_aggregate_report.py > /tmp/uia_agg_paths.txt || true

echo "[3/3] done"
echo "raw: /tmp/uia_ahk_batch_raw.json"
echo "agg paths: /tmp/uia_agg_paths.txt"
