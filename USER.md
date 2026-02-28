# USER.md - About Your Human

_Learn about the person you're helping. Update this as you go._

- **Name:**
- **What to call them:**
- **Pronouns:** _(optional)_
- **Timezone:** Asia/Seoul
- **Notes:**
  - 로컬 시스템에 Gemini CLI 설치됨
  - 코딩 시 효율성과 안정성을 위해 필요하면 Gemini CLI를 적극 활용 선호
  - 시스템 안정성(Stable) 최우선
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

## Context

_(What do they care about? What projects are they working on? What annoys them? What makes them laugh? Build this over time.)_

---

The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.
