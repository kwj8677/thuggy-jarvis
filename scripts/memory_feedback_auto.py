#!/usr/bin/env python3
import argparse
import json
import subprocess
from pathlib import Path

CTX = Path('/tmp/openclaw/memory-context-latest.json')
FDBK = '/home/humil/.openclaw/workspace/scripts/memory_feedback.py'

POS = ['맞아', '정확', '좋아', 'ㅇㅇ', 'ok']
NEG = ['아니', '틀', '수정', '아님']


def main():
    ap = argparse.ArgumentParser(description='Auto feedback from short user signal')
    ap.add_argument('--text', required=True)
    args = ap.parse_args()

    if not CTX.exists():
        print(json.dumps({'ok': False, 'reason': 'context_missing'}))
        return
    d = json.loads(CTX.read_text(encoding='utf-8'))
    items = ((d.get('recall') or {}).get('items') or [])
    if not items:
        print(json.dumps({'ok': False, 'reason': 'no_recall_items'}))
        return

    top = items[0]
    t = args.text.lower()
    signal = None
    if any(k in t for k in NEG):
        signal = 'correct'
    elif any(k in t for k in POS):
        signal = 'confirm'

    if not signal:
        print(json.dumps({'ok': True, 'applied': False, 'reason': 'no_signal'}))
        return

    cmd = [FDBK, '--id', top.get('id'), '--signal', signal, '--note', f'auto-feedback: {args.text[:80]}']
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode == 0:
        print(p.stdout.strip())
    else:
        print(json.dumps({'ok': False, 'applied': False, 'stderr': p.stderr[:300]}))


if __name__ == '__main__':
    main()
