# Queue Reliability v1 (Busy-queue freeze/duplicate mitigation)

## Goal
작업 중 대화창 먹통/중복응답 문제를 줄이기 위한 큐 신뢰성 강화.

## Core controls
1. Dedupe TTL/Key
- key: `chat_id + sender_id + normalized_text`
- `time_bucket`는 중복률 회귀를 유발할 수 있어 기본 비활성화
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
- observed (latest):
  - baseline: duplicate=0.0347 / p95=106000ms
  - shaped(1s gap): duplicate=0.0457 / p95=39000ms
  - shaped+tuned-dedupe(no bucket): duplicate=0.0000 / p95=26000ms
  - out_of_order_rate: 0.0
- interpretation: ingress shaping 단독은 duplicate 회귀 위험이 있으나, dedupe key에서 time_bucket을 제거하면 p95와 duplicate를 동시에 개선 가능

## Reference triage (apply / hold / observe)

### Apply
- OpenClaw PR #5219 (queue visibility + concurrent processing)
- OpenClaw issue #30604 (TTL dedupe cache idea)
- Idempotent consumer patterns (Kafka/RabbitMQ)

### Hold
- Full token-bucket ingress shaping at gateway layer (needs broader impact check)
- Priority interrupt lane for all channels (risk of ordering side effects)

### Observe
- OpenClaw queued duplicate issues (#34041/#34039) resolution status
- Queue order anomaly issue (#9278) updates
- queue_wait_ms_p95 trend vs duplicate_delivery_rate

## Reference links
- https://github.com/openclaw/openclaw/pull/5219
- https://github.com/openclaw/openclaw/issues/30604
- https://github.com/openclaw/openclaw/issues/34041
- https://github.com/openclaw/openclaw/issues/34039
- https://github.com/openclaw/openclaw/issues/9278
- https://github.com/lydtechconsulting/kafka-idempotent-consumer
- https://github.com/fencyio/fency
- https://github.com/bbeck/token-bucket

## Report format
1. 더블체크
2. 결론
3. 냉정한 반론
4. 다음 액션
