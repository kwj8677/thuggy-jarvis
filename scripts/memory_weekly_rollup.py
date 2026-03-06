#!/usr/bin/env python3
import argparse
import datetime as dt
import glob
import json
from pathlib import Path

BASE = Path('/home/humil/.openclaw/workspace')
MEM_DIR = BASE / 'memory'
ITEMS = MEM_DIR / 'memory_items.jsonl'
STATE = MEM_DIR / 'memory-rollup-state.json'


def load_items():
    out = []
    if not ITEMS.exists():
        return out
    for ln in ITEMS.read_text(encoding='utf-8', errors='replace').splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            out.append(json.loads(ln))
        except Exception:
            pass
    return out


def this_week_file() -> Path:
    now = dt.datetime.now()
    y, w, _ = now.isocalendar()
    return MEM_DIR / f'weekly-{y}-W{w:02d}.md'


def recent_daily_notes(days=7):
    files = sorted(glob.glob(str(MEM_DIR / '2026-*.md')))[-days:]
    lines = []
    for f in files:
        p = Path(f)
        txt = p.read_text(encoding='utf-8', errors='replace').strip()
        if txt:
            first = txt.splitlines()[:8]
            lines.append((p.name, first))
    return lines


def load_state():
    if not STATE.exists():
        return {}
    try:
        return json.loads(STATE.read_text(encoding='utf-8'))
    except Exception:
        return {}


def save_state(st):
    STATE.write_text(json.dumps(st, ensure_ascii=False, indent=2), encoding='utf-8')


def main():
    ap = argparse.ArgumentParser(description='memory weekly rollup (daily gate)')
    ap.add_argument('--once-per-day', action='store_true', default=True)
    ap.add_argument('--force', action='store_true')
    args = ap.parse_args()

    today = dt.date.today().isoformat()
    st = load_state()
    if args.once_per_day and not args.force and st.get('last_run_date') == today:
        print(json.dumps({'ok': True, 'skipped': True, 'reason': 'already_ran_today', 'last_run_date': today}, ensure_ascii=False, indent=2))
        return

    items = load_items()
    active = [i for i in items if i.get('status', 'active') == 'active']
    superseded = [i for i in items if i.get('status') == 'superseded']

    by_type = {}
    for i in active:
        by_type[i.get('type', 'unknown')] = by_type.get(i.get('type', 'unknown'), 0) + 1

    p = this_week_file()
    recents = recent_daily_notes(7)

    out = []
    out.append(f"# Weekly Memory Rollup - {dt.datetime.now().strftime('%Y-%m-%d %H:%M')}")
    out.append('')
    out.append('## Snapshot')
    out.append(f"- active items: {len(active)}")
    out.append(f"- superseded items: {len(superseded)}")
    out.append(f"- type counts: {json.dumps(by_type, ensure_ascii=False)}")
    out.append('')
    out.append('## Top Active Decisions/Preferences')
    for i in active[:10]:
        out.append(f"- [{i.get('type')}] {i.get('text')} (conf={i.get('confidence')})")
    out.append('')
    out.append('## Recent Daily Notes (head)')
    for name, head in recents:
        out.append(f"- {name}")
        for ln in head[:4]:
            out.append(f"  - {ln}")
    out.append('')
    out.append('## Next Actions')
    out.append('- Review superseded items and prune if stale.')
    out.append('- Promote durable items into MEMORY.md when confirmed.')

    p.write_text('\n'.join(out) + '\n', encoding='utf-8')

    st['last_run_date'] = today
    st['last_weekly_file'] = str(p)
    save_state(st)

    print(json.dumps({'ok': True, 'weekly_file': str(p), 'active': len(active), 'superseded': len(superseded), 'skipped': False}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
