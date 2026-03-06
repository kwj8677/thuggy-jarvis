#!/usr/bin/env python3
import datetime as dt
import json
from pathlib import Path

BASE = Path('/home/humil/.openclaw/workspace')
M = BASE / 'memory' / 'memory-metrics.json'
OUT_DIR = BASE / 'memory'


def main():
    if not M.exists():
        print(json.dumps({'ok': False, 'reason': 'metrics_not_found'}))
        return

    d = json.loads(M.read_text(encoding='utf-8'))
    m = d.get('metrics', {})
    inv = int(m.get('memory_recall_invocations', 0))
    hit = int(m.get('memory_recall_hits', 0))
    reexp = int(m.get('re_explain_count', 0))
    wrong = int(m.get('wrong_past_reference_count', 0))

    hit_rate = (hit / inv * 100.0) if inv > 0 else 0.0

    y, w, _ = dt.datetime.now().isocalendar()
    out = OUT_DIR / f'weekly-metrics-{y}-W{w:02d}.md'

    lines = [
        f"# Weekly Memory Metrics - {dt.datetime.now().strftime('%Y-%m-%d %H:%M')}",
        "",
        "## KPIs",
        f"- recall invocations: {inv}",
        f"- recall hits: {hit}",
        f"- recall hit rate: {hit_rate:.1f}%",
        f"- re-explain count: {reexp}",
        f"- wrong past reference count: {wrong}",
        "",
        "## Assessment",
    ]

    if hit_rate >= 70 and wrong <= 1:
        lines.append('- memory quality: good (maintain current policy)')
    elif hit_rate >= 50:
        lines.append('- memory quality: moderate (tune recall query/min-score)')
    else:
        lines.append('- memory quality: low (review capture quality + recall weights)')

    out.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    print(json.dumps({'ok': True, 'out': str(out), 'hit_rate': round(hit_rate, 2)}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
