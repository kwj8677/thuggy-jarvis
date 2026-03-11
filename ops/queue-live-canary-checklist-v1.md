# Queue Live Canary Checklist v1

## Scope
- 대상: Telegram direct 채널 우선
- 트래픽: 전체의 10% 이하
- 기간: 최소 30분 ~ 최대 2시간

## Preflight
- [ ] 현재 정책 버전 확인: `ops/queue-reliability-v1.json`
- [ ] dedupe key = `chat_id + sender_id + normalized_text`
- [ ] `timeBucketEnabled=false`
- [ ] rollback 기준/명령 사전 준비
- [ ] 관측 리포트 경로 준비 (`reports/queue-live-canary-*.md`)

## Canary runtime guards
- [ ] 단일 변경만 적용 (큐 정책 외 동시 변경 금지)
- [ ] max retry/cooldown/circuit-break 기존값 유지
- [ ] 운영 중 polling loop 금지

## SLO / Acceptance
- [ ] duplicate_delivery_rate <= baseline(0.0347) and target <= 0.01
- [ ] queue_wait_ms_p95 <= 60000 (1차), stretch <= 30000
- [ ] out_of_order_rate = 0
- [ ] runaway loop / retry storm = 0

## Abort conditions (즉시 중단)
- [ ] duplicate_delivery_rate > baseline + 0.01
- [ ] queue_wait_ms_p95 > baseline(106000ms)
- [ ] out_of_order_rate > 0
- [ ] 사용자 체감 장애(먹통/중복응답) 다수 보고

## Rollback
- [ ] canary off -> baseline policy 복구
- [ ] 10분 관측 후 지표 안정 확인
- [ ] 원인 로그/요약 리포트 작성

## Reporting format
1. 더블체크
2. 결론
3. 냉정한 반론
4. 다음 액션
