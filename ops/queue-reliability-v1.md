# Queue Reliability v1 (Busy-queue freeze/duplicate mitigation)

## Goal
작업 중 대화창 먹통/중복응답 문제를 줄이기 위한 큐 신뢰성 강화.

## Core controls
1. Dedupe TTL/Key
- key: `chat_id + sender_id + normalized_text + time_bucket`
- ttl: 5~20 minutes

2. Ordering policy
- default: FIFO strict
- interrupt path: separate priority lane only

3. Safety guard
- retry cap + cooldown + circuit-break
- non-retryable config errors => immediate stop

## Metrics
- duplicate_delivery_rate
- queue_wait_ms (p50/p95)
- resend_rate (same user repeated prompt)
- out_of_order_rate

## Rollout strategy
1. Shadow mode (observe only)
2. Canary rollout (small traffic)
3. Full rollout if metrics improve

## Pass criteria
- duplicate_delivery_rate near 0
- queue_wait p95 improved
- no runaway loop

## Canary simulation status (v1)
- report: `reports/queue-canary-sim-v1.json`
- observed:
  - duplicate_delivery_rate: 0.0291
  - queue_wait_ms_p95: 105449
  - out_of_order_rate: 0.0
- interpretation: 중복 전달률은 낮지만 p95 대기시간은 여전히 길어, 큐 처리량/우선순위 정책 추가 검토 필요

## Report format
1. 더블체크
2. 결론
3. 냉정한 반론
4. 다음 액션
