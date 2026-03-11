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

## Report format
1. 더블체크
2. 결론
3. 냉정한 반론
4. 다음 액션
