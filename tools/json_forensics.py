#!/usr/bin/env python3
import json
import os
from pathlib import Path
from datetime import datetime

SCAN_DIRS = [
    Path('/home/humil/.openclaw'),
    Path('/home/humil/.openclaw/workspace'),
]
EXCLUDE_PARTS = {'.git', 'node_modules', '.venv', '__pycache__'}
OUT_DIR = Path('/home/humil/.openclaw/workspace/memory/forensics')
OUT_DIR.mkdir(parents=True, exist_ok=True)

now = datetime.now().strftime('%Y-%m-%dT%H:%M:%S%z')
report_path = OUT_DIR / f'json-forensics-{datetime.now().strftime("%Y%m%d-%H%M%S")}.md'
latest_path = OUT_DIR / 'json-forensics-latest.md'

ok = []
bad = []

for root in SCAN_DIRS:
    if not root.exists():
        continue
    for p in root.rglob('*.json'):
        if any(part in EXCLUDE_PARTS for part in p.parts):
            continue
        try:
            txt = p.read_text(errors='replace')
            json.loads(txt)
            ok.append(p)
        except Exception as e:
            st = p.stat()
            bad.append((p, str(e), st.st_size, datetime.fromtimestamp(st.st_mtime).isoformat()))

lines = []
lines.append(f'# JSON Forensics Report\n')
lines.append(f'- Generated: {now}')
lines.append(f'- Scanned dirs: ' + ', '.join(str(x) for x in SCAN_DIRS))
lines.append(f'- Valid JSON files: {len(ok)}')
lines.append(f'- Invalid JSON files: {len(bad)}\n')

if bad:
    lines.append('## Invalid JSON Details')
    for p, e, size, mtime in bad:
        lines.append(f'- `{p}`')
        lines.append(f'  - size: {size} bytes')
        lines.append(f'  - mtime: {mtime}')
        lines.append(f'  - error: `{e}`')
else:
    lines.append('## Invalid JSON Details')
    lines.append('- none')

content = '\n'.join(lines) + '\n'
report_path.write_text(content)
latest_path.write_text(content)
print(str(report_path))
print(f'bad={len(bad)} ok={len(ok)}')
