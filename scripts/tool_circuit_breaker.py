#!/usr/bin/env python3
import json
import re
import time
from pathlib import Path

LOG = Path('/tmp/openclaw/openclaw-2026-03-07.log')
STATE = Path('/home/humil/.openclaw/workspace/memory/tool-circuit-state.json')

PATTERNS = {
    'browser': re.compile(r'\bbrowser\b.*(failed|timeout)', re.I),
    'exec': re.compile(r'\bexec\b.*(failed|timeout)', re.I),
    'gateway': re.compile(r'gateway timeout|FailoverError|embedded run timeout', re.I),
}

THRESHOLD = 3
WINDOW_SEC = 1800
COOLDOWN_SEC = 900


def load_state():
    if not STATE.exists():
        return {'events': [], 'open': {}}
    try:
        return json.loads(STATE.read_text(encoding='utf-8'))
    except Exception:
        return {'events': [], 'open': {}}


def save_state(s):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(s, ensure_ascii=False, indent=2), encoding='utf-8')


def main():
    now = int(time.time())
    st = load_state()
    lines = []
    if LOG.exists():
        lines = LOG.read_text(encoding='utf-8', errors='replace').splitlines()[-1500:]

    for ln in lines:
        for tool, pat in PATTERNS.items():
            if pat.search(ln):
                st['events'].append({'ts': now, 'tool': tool})

    cutoff = now - WINDOW_SEC
    st['events'] = [e for e in st['events'] if e['ts'] >= cutoff]

    result = {'opened': [], 'active': [], 'closed': []}
    for tool in PATTERNS.keys():
        cnt = sum(1 for e in st['events'] if e['tool'] == tool)
        opened_at = st.get('open', {}).get(tool)
        if cnt >= THRESHOLD and not opened_at:
            st.setdefault('open', {})[tool] = now
            result['opened'].append({'tool': tool, 'count': cnt})
        elif opened_at:
            if now - opened_at >= COOLDOWN_SEC and cnt < THRESHOLD:
                del st['open'][tool]
                result['closed'].append({'tool': tool, 'count': cnt})
            else:
                result['active'].append({'tool': tool, 'count': cnt, 'opened_at': opened_at})

    save_state(st)
    print(json.dumps({'ok': True, 'result': result, 'state': str(STATE)}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
