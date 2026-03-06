#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

P = Path('/home/humil/.openclaw/workspace/memory/memory-metrics.json')


def load():
    if not P.exists():
        return {
            'version': 1,
            'period_days': 14,
            'started_at': None,
            'metrics': {
                're_explain_count': 0,
                'wrong_past_reference_count': 0,
                'memory_recall_invocations': 0,
                'memory_recall_hits': 0,
            },
        }
    return json.loads(P.read_text(encoding='utf-8'))


def main():
    ap = argparse.ArgumentParser(description='Update memory quality metrics')
    ap.add_argument('--re-explain', type=int, default=0)
    ap.add_argument('--wrong-ref', type=int, default=0)
    ap.add_argument('--recall-invoke', type=int, default=0)
    ap.add_argument('--recall-hit', type=int, default=0)
    args = ap.parse_args()

    d = load()
    m = d.setdefault('metrics', {})
    m['re_explain_count'] = int(m.get('re_explain_count', 0)) + args.re_explain
    m['wrong_past_reference_count'] = int(m.get('wrong_past_reference_count', 0)) + args.wrong_ref
    m['memory_recall_invocations'] = int(m.get('memory_recall_invocations', 0)) + args.recall_invoke
    m['memory_recall_hits'] = int(m.get('memory_recall_hits', 0)) + args.recall_hit

    P.write_text(json.dumps(d, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'ok': True, 'metrics': m}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
