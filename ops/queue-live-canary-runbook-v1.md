# Queue Live Canary Runbook v1

## 목적
실트래픽 소량 카나리(Queue reliability tuned policy) 안전 적용/중단/복구 절차.

## 대상 정책
- `ops/queue-reliability-v1.json`
- 핵심: dedupe key=`chat_id+sender_id+normalized_text`, `timeBucketEnabled=false`

## 실행 전 (T-10m)
1. 기준선 확보
   - baseline 지표 확인: duplicate=0.0347, p95=106000ms, out_of_order=0.0
2. 변경 동결
   - 큐 정책 외 동시 변경 금지
3. 중단/복구 준비
   - baseline 정책 백업 확인
   - 중단 조건 공유

## 카나리 실행 (10% 이하)
1. 카나리 시작
   - 대상: Telegram direct
   - 비율: <=10%
2. 관측 주기
   - 10분 단위 체크 (과폴링 금지)
3. 수집 지표
   - duplicate_delivery_rate
   - queue_wait_ms_p95
   - out_of_order_rate
   - runaway/retry storm 여부

## 합격 기준
- duplicate_delivery_rate <= 0.01 (최소 baseline 이하)
- queue_wait_ms_p95 <= 60000 (stretch 30000)
- out_of_order_rate = 0
- 사용자 체감 장애(먹통/중복응답) 없음

## 즉시 중단 조건
- duplicate_delivery_rate > baseline + 0.01
- queue_wait_ms_p95 > baseline
- out_of_order_rate > 0
- 사용자 장애 신고 다수

## 중단/복구
1. 카나리 OFF
2. baseline 정책 복구
3. 10분 관측 안정화 확인
4. 원인/교훈 기록 (보고서)

## 보고 템플릿
1) 더블체크
- 적용 범위/시간/표본 수

2) 결론
- pass/fail + 핵심 수치

3) 냉정한 반론
- 데이터 한계/채널 편향/잔여 리스크

4) 다음 액션
- 확대/유지/롤백/추가실험 중 1개 결정
