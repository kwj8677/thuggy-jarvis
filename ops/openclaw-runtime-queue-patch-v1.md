# OpenClaw Runtime Queue Patch v1 (Draft)

## 목적
시뮬레이션에서 검증한 정책(중복 제거 + FIFO + 가드)을 OpenClaw 런타임 경로에 안전하게 반영하기 위한 패치 초안.

## 적용 대상(코드 레벨)
1. `src/auto-reply/inbound-debounce.ts`
- `debounceMs=0` 경로에서 blocking await 대신 non-blocking fire-and-forget 유지
- busy 시 followup queue enqueue 시 dedupe key 적용

2. `src/channels/inbound-debounce-policy.ts`
- 채널별 policy에 canary gate(10%) 및 dedupe 옵션 제공

## 정책 파라미터(초기값)
- dedupe.key = `chat_id + sender_id + normalized_text`
- dedupe.ttlMinutes = 10
- dedupe.timeBucketEnabled = false
- ordering = FIFO
- priorityLaneOnlyFor = [explicit-steer, stop, audit]

## 실패 안전장치
- runtime flag: `QUEUE_CANARY_ENABLED` (default false)
- runtime flag: `QUEUE_CANARY_PERCENT` (default 10)
- abort on anomaly: duplicate spike / out-of-order > 0 / retry storm

## 검증 단계
1. unit-level 시나리오
- same text resend -> single delivery
- different text burst -> FIFO order preserved

2. canary(10%)
- 30~120분 관측
- metrics: duplicate_delivery_rate, queue_wait_ms_p95, out_of_order_rate

3. rollback
- canary off -> baseline behavior

## 주의
- OpenClaw 설치본(dist) 직접 수정은 업데이트 시 덮어써질 수 있음.
- 가능하면 소스 레포 기반 PR로 반영 권장.
