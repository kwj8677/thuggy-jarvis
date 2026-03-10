# Engineering Routine (Stable-first)

이 문서는 연진/클로 운영에서 실제로 지키는 작업 방식과 루틴을 고정한다.

## Core goals
- 운영 목표: **Stable**
- API 낭비 최소화
- 작은 변경 + 빠른 검증 + 원인 분리

## Working pattern
1. **문제 분해 (First Principles)**
   - 증상/원인/가설을 분리
2. **작은 변경 1개 적용**
   - 한 번에 여러 변경 금지
3. **즉시 스모크 테스트 (3회)**
4. **본배치 테스트 (10회)**
5. **기준 통과 시만 반영**
6. **문서(md/json) 동시 업데이트**

## Update routine (fixed)
1. 레퍼런스 수집
2. GitHub 참고자료 확인
3. 비교/메타인지 분석
4. 3회 스모크 -> 10회 배치
5. 적용
6. md/json 동시 업데이트
7. GitHub 커밋/푸시
8. 보고(더블체크->결론->반론->다음 액션)

## Vibe coding safety principles
1. 작은 변경 1개씩 (원인 추적 가능성 유지)
2. 바로 검증 3회->10회 (감이 아니라 재현율로 판단)
3. 가드 고정 (maxRetry/cooldown/circuit-break)
4. 상태기반 성공판정 (실행됨 != 변화됨)
5. md + json 동시 관리 (원칙/파라미터 분리)
6. 보고 포맷 고정 (판단 오차 최소화)

## Guardrails
- `maxRetry=1`
- `cooldownSec>=30`
- single-instance lock
- circuit-break on consecutive failures
- non-retryable config errors => immediate stop
- API call cap enforced

## Success criteria
- success rate >= 90%
- retries near 0
- error bucket mostly `NONE`
- no circuit-break for healthy scenarios

## Reporting format
항상 아래 순서:
1. 더블체크
2. 결론
3. 냉정한 반론(한계/대안)
4. 다음 액션

## Change management
- 고위험 변경: 사전 확인 필수
- Gateway restart: 사용자 승인 후 1회
- 적용 후 로그/요약 JSON 첨부

## Weekly maintenance
- 레퍼런스 패턴 재검토
- 재현율 드리프트 확인
- 불필요 단계/중복 호출 제거

## Reference sources (GitHub)
- Microsoft Engineering Playbook
  - https://github.com/microsoft/code-with-engineering-playbook
- FlaUI
  - https://github.com/FlaUI/FlaUI
  - https://github.com/FlaUI/FlaUI/wiki/Searching
  - https://github.com/FlaUI/FlaUI/wiki/Retry
- pywinauto timings
  - https://github.com/vsajip/pywinauto/blob/master/pywinauto/timings.py
- Polly resilience
  - https://github.com/App-vNext/Polly
  - https://github.com/App-vNext/Polly-Samples
- SRE checklist
  - https://github.com/bregman-arie/sre-checklist
