# USER.md - About Your Human

_Learn about the person you're helping. Update this as you go._

- **Name:**
  김연진
- **What to call them:**
  연진
- **Pronouns:** _(optional)_
- **Timezone:** Asia/Seoul
- **Notes:**
  - 로컬 시스템에 Gemini CLI 설치됨
  - 코딩 시 효율성과 안정성을 위해 필요하면 Gemini CLI를 적극 활용 선호
  - 운영 목표: Stable
  - 보안보다 안정성/가용성을 우선하되, 고위험 변경은 사전 확인 후 진행
  - 시스템 설정값이 민감한 경우 임의 변경 금지, 변경 전 반드시 확인
  - OpenClaw가 WSL에 설치된 환경이므로, Windows 작업은 무조건 WSL에서 `powershell.exe`(pwsh) 호출 방식으로 수행
  - 토큰/인증값은 CLI 출력 마스킹값이 아니라 `~/.openclaw/openclaw.json`에서 직접 읽어 사용
  - 중요한 운영 규칙/자동화 변경사항은 JSON 파일과 스킬 프롬프트(워크스페이스 기준)에 수시로 저장·수정·정리
  - 앞으로 Gemini CLI를 작업 전반에 적극 활용 (요약/초안/분석/자동화 보조)
  - OpenClaw 모델 타임아웃/실패 시 보조 경로로 Windows Gemini CLI(wsl→pwsh) 즉시 사용
  - Windows 패키지/도구 설치·업데이트는 Chocolatey를 우선 경로로 적극 활용
  - Windows 작업 명령은 `psw "<명령어>"` 패턴으로 통일하여 실행 (예: `psw "Get-Date"`, `psw "Get-Process | Select -First 3"`, `psw "Start-Process notepad"`)
  - GUI 자동화는 AHK(v2)+`C:\openclaw\run.ps1` 액션 체계를 우선 사용하고, 브라우저는 Relay 우선
  - 모든 주요 시크릿(API 키/토큰/IP)은 `secrets/local-secrets.json`에 로컬 저장하고, 작업 시 해당 JSON을 우선 참조한다
  - 시크릿은 기억에 의존하지 않고 파일(`secrets/local-secrets.json`)을 단일 진실원(SoT)으로 사용한다
  - 세션은 분리하되 공통 기억(MEMORY.md, memory/*.md)은 통합 활용하고, 필요 시 다른 세션 기록(sessions_history)도 자율적으로 조회해 문맥을 보완한다
  - 사용자 채팅은 단일 스레드로 유지하고, 내부적으로 작업 맥락(운영/마케팅/실험)을 자동 분류·분리하여 처리 후 통합 보고한다 (사용자에게 태그 입력 요구하지 않음)
  - 중요 이슈 답변 시 "더블체크 → 결론 → 냉정한 반론(한계/대안) → 다음 액션" 형식의 보고를 선호
  - 작업이 끝나거나 timeout/오류가 나도 반드시 마지막에 결과 보고 라인(성공/실패/원인/다음액션)을 남길 것
  - API 호출량 낭비를 매우 싫어함: 중복 호출/반복 폴링/과도한 proactive 체크 지양, 변경은 묶어서 1회 적용 선호
  - 운영 정책: 모든 작업의 단일 진입점은 Python runner로 통일하고, 내부 실행기는 목적별 어댑터로 분리(웹=Python+Playwright, Windows 시스템=Python에서 PowerShell 호출)
  - 에이전트 운용 원칙: Heavy 1(메인)은 지휘/판단만, Light 4(서브)는 병렬 생성+직렬 감사로 분산 처리
  - 웹 자동화 스택 고정: 로컬 Python+Playwright(주력) + `playwright-cli`(보조)만 사용 (`agent-browser`, `stealth-browser`는 사용 금지)
  - 웹 실행 모드 규칙: 검색/수집/리서치는 headless 기본, UI 조작/디버깅/복잡 인터랙션은 headful 전환
  - 권한 정책: Python 상시 관리자권한 고정 금지. 기본 일반권한 실행, 관리자권한은 고위험 작업에서만 조건부 승격(whitelist 기반)
  - 고위험 액션 게이트: 결제/송금/외부 발송(메일·메시지) 최종 실행 전 사용자 확인 1회 필수

## Context

_(What do they care about? What projects are they working on? What annoys them? What makes them laugh? Build this over time.)_

---

The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.
