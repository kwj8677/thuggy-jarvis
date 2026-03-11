#!/usr/bin/env python3
import json
import random
import statistics
import time
from collections import deque
from pathlib import Path


def percentile(data, p):
    if not data:
        return 0
    data = sorted(data)
    k = (len(data) - 1) * (p / 100.0)
    f = int(k)
    c = min(f + 1, len(data) - 1)
    if f == c:
        return data[f]
    return data[f] + (data[c] - data[f]) * (k - f)


def simulate(seed=42, n=200, dedupe_ttl_sec=600):
    random.seed(seed)
    now = int(time.time())
    queue = deque()
    delivered = []
    dedupe = {}
    enqueue_ts = {}

    def key(m):
        bucket = (m['ts'] // 30)
        norm = m['text'].strip().lower()
        return (m['chat_id'], m['sender_id'], norm, bucket)

    # generate bursty traffic
    msgs = []
    t = now
    for i in range(n):
        if random.random() < 0.15:
            txt = '상태 알려줘'  # duplicated common prompt
        else:
            txt = f'msg-{i}'
        msgs.append({'id': i, 'chat_id': 'telegram:7032536273', 'sender_id': 'u1', 'text': txt, 'ts': t})
        t += random.randint(0, 2)  # burst arrivals

    dropped_dupes = 0
    for m in msgs:
        k = key(m)
        prev = dedupe.get(k)
        if prev and (m['ts'] - prev) < dedupe_ttl_sec:
            dropped_dupes += 1
            continue
        dedupe[k] = m['ts']
        queue.append(m)
        enqueue_ts[m['id']] = m['ts']

    proc_t = now
    while queue:
        m = queue.popleft()
        # processing jitter
        proc_t += random.randint(0, 3)
        delivered.append((m, proc_t))

    # metrics
    waits = []
    seen = set()
    dup_delivered = 0
    out_of_order = 0
    last_id = -1
    for m, dt in delivered:
        waits.append(max(0, dt - enqueue_ts[m['id']]))
        sig = (m['chat_id'], m['sender_id'], m['text'].strip().lower())
        if sig in seen:
            dup_delivered += 1
        seen.add(sig)
        if m['id'] < last_id:
            out_of_order += 1
        last_id = m['id']

    result = {
        'input_count': len(msgs),
        'queued_count': len(delivered),
        'dropped_dupes': dropped_dupes,
        'duplicate_delivery_rate': round(dup_delivered / max(1, len(delivered)), 4),
        'queue_wait_ms_p50': int(percentile([w * 1000 for w in waits], 50)),
        'queue_wait_ms_p95': int(percentile([w * 1000 for w in waits], 95)),
        'out_of_order_rate': round(out_of_order / max(1, len(delivered)), 4)
    }
    return result


def main():
    res = simulate()
    base = Path('/home/humil/.openclaw/workspace/reports')
    out_json = base / 'queue-canary-sim-v1.json'
    out_md = base / 'queue-canary-sim-v1.md'
    out_json.write_text(json.dumps({'generated_at': time.strftime('%Y-%m-%d %H:%M:%S KST'), 'result': res}, indent=2, ensure_ascii=False))

    md = [
        '# Queue Canary Simulation v1',
        '',
        f"- input_count: {res['input_count']}",
        f"- queued_count: {res['queued_count']}",
        f"- dropped_dupes: {res['dropped_dupes']}",
        f"- duplicate_delivery_rate: {res['duplicate_delivery_rate']}",
        f"- queue_wait_ms_p50: {res['queue_wait_ms_p50']}",
        f"- queue_wait_ms_p95: {res['queue_wait_ms_p95']}",
        f"- out_of_order_rate: {res['out_of_order_rate']}"
    ]
    out_md.write_text('\n'.join(md) + '\n')
    print(out_json)
    print(out_md)
    print(res)


if __name__ == '__main__':
    main()
