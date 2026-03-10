# macOS-grade Control Expansion v1 (Windows + WSL)

## Goal
윈도우 환경에서 macOS급 제어 체감(재현성/회복력/속도)을 달성한다.

## Scope v1
1. 기존 UIA 파이프라인(L3/L4/L5) 안정성 유지
2. Relay-less 브라우징 파이프라인 추가
3. UIA-first + Browser agent + Vision fallback 하이브리드 구축

## Architecture
- Primary control: `windows-uia-ops` stages
- Browser control (non-relay): OpenClaw browser automation path
- Fallback: desktop vision control (최소 사용)
- Guard rails: retry/cooldown/circuit-break/api-cap/timeout

## Execution sequence
1) Baseline freeze
- L3/L4/L5 최근 기준선 저장

2) Browser pipeline v1
- search -> collect -> verify -> summarize
- 1 task = 1 bounded run

3) Hybrid orchestration rule
- UIA-first for app/system flows
- Browser agent for web flows
- Vision only when UIA/DOM path fails

4) Stage tests
- smoke: 3 runs per flow
- batch: 10 runs per flow

5) Quality gate
- success >= 90%
- retry_rate <= 10%
- fallback_rate <= 20%
- no runaway loops

## Metrics
- pass/fail/retry
- api_calls total + role breakdown
- error_bucket distribution
- avg runtime per run

## Report format
1. 더블체크
2. 결론
3. 냉정한 반론
4. 다음 액션

## Change policy
- single change per cycle
- docs(json/md) sync required
- high-risk change needs approval
