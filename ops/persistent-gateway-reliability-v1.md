# Persistent Gateway Reliability v1

## Objective
부팅/재시작/채널 스톨 상황에서 원인 추적과 복구를 **재현 가능하고 지속 가능한 방식**으로 표준화한다.

## SLO
- Gateway port collision: 0 (정상 절차에서)
- Telegram polling stall MTTR: <= 5 min
- Unknown first-launcher incidents: 0 (항상 증거 수집)

## Standard lifecycle
1. Start: `openclaw gateway start`
2. Verify: `openclaw gateway status` + `ss -ltnp | grep 18789`
3. Channel check: 최근 로그에 polling stall/network fail 유무 확인
4. Stop: `openclaw gateway stop`

## Recovery protocol (port occupied)
1. `openclaw gateway stop`
2. `ss -ltnp | grep 18789`
3. 잔존 PID만 종료
4. `openclaw gateway start`
5. 상태/채널 확인

## Forensics protocol (boot anomaly)
- 파일: `C:\openclaw\forensics\boot-capture-*.log`
- 반드시 포함할 항목:
  - process list (openclaw/wsl/node)
  - pid/ppid/cmdline
  - netstat 18789/18791
  - scheduled task snapshot

## Decision policy
- 단일 원인 단정 금지: 항상 `실행 경로`와 `채널 상태`를 분리 보고
- 결론 포맷: 더블체크 → 결론 → 반론 → 다음 액션

## Continuous improvements
- run.ps1 메타 판정 로직 유지보수
- 부팅 캡처 태스크는 SYSTEM + AtStartup로 고정(관리자 승인 필요)
- 월 1회 runbook 리허설
