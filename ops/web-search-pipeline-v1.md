# Web Search Pipeline v1 (2026-03-13)

## 목적
- 비용 절감 + 정확도 유지 + 실행 안정성 확보

## 고정 원칙
- 단일 진입점: Python runner
- 주력 런타임: Python + Playwright
- 보조: `playwright-cli`
- 금지: `agent-browser`, `stealth-browser`

## 실행 모드
- 기본: headless
- headful 전환 조건:
  1) UI 상호작용 필요
  2) 디버그/시각 검증 필요
  3) 동적 렌더링/로그인 플로우

## 검색/추출 루틴
### 일반 웹 작업
1. 1차 검색: Brave 3개
2. 신뢰도 낮음: 8개 확장
3. 중요/충돌 건: 10개 + 교차검증
4. 본문 추출: 정적(fetch/parse) 우선
5. 실패 시: Playwright fallback

### 네이버 작업(고정)
1. Brave 사용 금지
2. Phase 1: headless Playwright로 네이버 플레이스 리스트/링크 수집
3. Phase 2: 디버그창(headful, 사용자 세션)에서 예약창 확인/검증
4. 지역 게이트(홍대/합정/상수/서교/마포) 미일치 결과 제외

## 고위험 액션 게이트
- 결제/송금/외부 발송은 최종 사용자 확인 1회 필수

## Windows 디버그창 표준
- 런처: `OpenClaw_DebugChrome_Interactive`
- 주요 장애: Session 0 숨은 Chrome 흡수
- 해결 패턴:
  1) Session 0 Chrome 정리
  2) Interactive Task(사용자 세션) 실행
  3) `powershell -> Start-Process(chrome)` 래퍼 사용

## 오케스트레이션 방식 (적용)
- Main: 오케스트레이션/최종판단만 수행
- 병렬 생성: 수집/분석/검증후보를 3워커 병렬 수행
- 직렬 감사: 감사 워커 1개가 형식/내용 게이트 판정
- 결정적 게이트: regex prefix + schema 검사로 최종 PASS/FAIL 확정
- 자동복구: FAIL/PARTIAL은 1회 재생성 후 재검사

## 필수 산출물
- 성공/실패 result JSON
- 실패 시 error log
- 필요 시 스크린샷 첨부
