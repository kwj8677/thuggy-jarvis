#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

CTX = Path('/tmp/openclaw/memory-context-latest.json')


def main():
    ap = argparse.ArgumentParser(description='Print concise memory preflight brief')
    ap.add_argument('--max-items', type=int, default=3)
    args = ap.parse_args()

    if not CTX.exists():
        print('NO_CONTEXT')
        return
    d = json.loads(CTX.read_text(encoding='utf-8'))
    items = (d.get('recall') or {}).get('items') or []
    if not items:
        print('NO_RECALL_ITEMS')
        return

    print('[Memory Preflight]')
    for it in items[: args.max_items]:
        print(f"- ({it.get('type')}) {it.get('text')} [score={it.get('score')}]")


if __name__ == '__main__':
    main()
