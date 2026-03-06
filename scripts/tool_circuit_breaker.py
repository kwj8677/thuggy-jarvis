#!/usr/bin/env python3
import glob
import json
import re
import time
from pathlib import Path

LOG_GLOB = '/tmp/openclaw/openclaw-*.log'
STATE = Path('/home/humil/.openclaw/workspace/memory/tool-circuit-state.json')

PATTERNS = {
    'browser': re.compile(r'\bbrowser\b.*(failed|timeout|closed before connect)', re.I),
    'exec': re.compile(r'\bexec\b.*(failed|timeout|killed)', re.I),
    'gateway': re.compile(r'gateway timeout|FailoverError|embedded run timeout|Port 18789 is already in use', re.I),
}

THRESHOLD = 3
WINDOW_SEC = 1800
COOLDOWN_SEC = 900


def latest_log() -> Path | None:
    files = sorted(glob.glob(LOG_GLOB))
    return Path(files[-1]) if files else None


def load_state():
    if not STATE.exists():
        return {'events': [], 'open': {}, 'cursor': {'log': None, 'line': 0}}
    try:
        s = json.loads(STATE.read_text(encoding='utf-8'))
        s.setdefault('events', [])
        s.setdefault('open', {})
        s.setdefault('cursor', {'log': None, 'line': 0})
        return s
    except Exception:
        return {'events': [], 'open': {}, 'cursor': {'log': None, 'line': 0}}


def save_state(s):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(s, ensure_ascii=False, indent=2), encoding='utf-8')


def read_new_lines(st, logp: Path):
    lines = logp.read_text(encoding='utf-8', errors='replace').splitlines()
    cur = st.get('cursor', {})
    if cur.get('log') != str(logp):
        start = max(0, len(lines) - 1500)
    else:
        start = int(cur.get('line', 0))
    new_lines = lines[start:]
    st['cursor'] = {'log': str(logp), 'line': len(lines)}
    return new_lines


def main():
    now = int(time.time())
    st = load_state()
    logp = latest_log()

    if logp and logp.exists():
        for ln in read_new_lines(st, logp):
            for tool, pat in PATTERNS.items():
                if pat.search(ln):
                    st['events'].append({'ts': now, 'tool': tool, 'sample': ln[:220]})

    cutoff = now - WINDOW_SEC
    st['events'] = [e for e in st['events'] if int(e.get('ts', 0)) >= cutoff]

    result = {'opened': [], 'active': [], 'closed': [], 'counts': {}}
    for tool in PATTERNS.keys():
        cnt = sum(1 for e in st['events'] if e['tool'] == tool)
        result['counts'][tool] = cnt
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
    print(json.dumps({'ok': True, 'result': result, 'state': str(STATE), 'log': str(logp) if logp else None}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
