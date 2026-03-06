#!/usr/bin/env python3
import json
import time
from pathlib import Path

ITEMS = Path('/home/humil/.openclaw/workspace/memory/memory_items.jsonl')
OUT = Path('/home/humil/.openclaw/workspace/memory/memory-drift-report.json')


def parse_ts(v):
    if not v:
        return int(time.time())
    try:
        if isinstance(v, int):
            return v
        if v.endswith('Z'):
            v = v[:-1] + '+00:00'
        return int(__import__('datetime').datetime.fromisoformat(v).timestamp())
    except Exception:
        return int(time.time())


def load_items():
    arr = []
    if not ITEMS.exists():
        return arr
    for ln in ITEMS.read_text(encoding='utf-8', errors='replace').splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            arr.append(json.loads(ln))
        except Exception:
            pass
    return arr


def main():
    now = int(time.time())
    items = load_items()

    stale_low_conf = []
    stale_days_threshold = 45
    conf_threshold = 0.55

    for it in items:
        if it.get('status', 'active') != 'active':
            continue
        ts = parse_ts(it.get('updated_at') or it.get('created_at'))
        age_days = (now - ts) / 86400
        conf = float(it.get('confidence', 0.6))
        if age_days >= stale_days_threshold and conf <= conf_threshold:
            stale_low_conf.append({
                'id': it.get('id'),
                'type': it.get('type'),
                'text': it.get('text'),
                'confidence': conf,
                'age_days': round(age_days, 1),
            })

    out = {
        'ok': True,
        'checked': len(items),
        'stale_low_conf_count': len(stale_low_conf),
        'items': stale_low_conf[:30],
        'policy': {
            'stale_days_threshold': stale_days_threshold,
            'confidence_threshold': conf_threshold,
        }
    }

    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'ok': True, 'out': str(OUT), 'stale_low_conf_count': len(stale_low_conf)}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
