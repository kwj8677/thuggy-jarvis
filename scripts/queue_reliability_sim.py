#!/usr/bin/env python3
import time
from collections import deque


def simulate(messages, ttl_sec=600):
    queue = deque()
    delivered = []
    dedupe = {}

    now = int(time.time())

    def key(msg):
        bucket = (now // 30)  # time bucket sample
        return (msg['chat_id'], msg['sender_id'], msg['text'].strip().lower(), bucket)

    # enqueue phase
    for m in messages:
        k = key(m)
        t = dedupe.get(k)
        if t and now - t < ttl_sec:
            continue
        dedupe[k] = now
        queue.append(m)

    # fifo drain
    while queue:
        delivered.append(queue.popleft())

    return delivered


if __name__ == '__main__':
    sample = [
        {'chat_id': 'telegram:1', 'sender_id': 'u1', 'text': '안녕'},
        {'chat_id': 'telegram:1', 'sender_id': 'u1', 'text': '안녕 '},
        {'chat_id': 'telegram:1', 'sender_id': 'u1', 'text': '상태 알려줘'},
        {'chat_id': 'telegram:1', 'sender_id': 'u2', 'text': '안녕'},
    ]
    out = simulate(sample)
    print('input=', len(sample), 'delivered=', len(out))
    for i,m in enumerate(out,1):
        print(i, m)
