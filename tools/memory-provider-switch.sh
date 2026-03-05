#!/usr/bin/env bash
set -euo pipefail
MODE=${1:-}
CFG=/home/humil/.openclaw/openclaw.json
if [[ "$MODE" != "auto" && "$MODE" != "ollama" ]]; then
  echo "Usage: $0 [auto|ollama]"
  exit 1
fi
python3 - <<PY
import json,datetime,shutil
p='$CFG'
ts=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
backup=f"{p}.bak-{ts}-memory-switch-$MODE"
shutil.copy2(p,backup)
j=json.load(open(p))
ms=j.setdefault('agents',{}).setdefault('defaults',{}).setdefault('memorySearch',{})
if '$MODE'=='auto':
    ms.clear(); ms['fallback']='ollama'
else:
    ms.clear(); ms['provider']='ollama'; ms['model']='bge-m3'; ms['fallback']='none'
with open(p,'w') as f: json.dump(j,f,ensure_ascii=False,indent=2)
print('backup',backup)
print('memorySearch',ms)
PY
openclaw config validate >/dev/null
echo "switched to $MODE"
