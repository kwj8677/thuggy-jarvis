# Windows UIA Reference Pack (Stable)

이 문서는 Windows 자동화 안정화에 직접 참고한 외부 레퍼런스를 고정해 둔 목록이다.

## Core references
- FlaUI core: https://github.com/FlaUI/FlaUI
- FlaUI searching patterns: https://github.com/FlaUI/FlaUI/wiki/Searching
- FlaUInspect (UIA inspect tool): https://github.com/FlaUI/FlaUInspect
- UIA-v2 (AHK): https://github.com/Descolada/UIA-v2
- UIAutomation (AHK): https://github.com/Descolada/UIAutomation
- pywinauto timings: https://github.com/vsajip/pywinauto/blob/master/pywinauto/timings.py
- Polly resilience: https://github.com/App-vNext/Polly
- OpenTelemetry log correlation (.NET): https://github.com/open-telemetry/opentelemetry-dotnet/blob/main/docs/logs/correlation/README.md

## Extracted patterns to apply
1. UIA-first selector hierarchy (`AutomationId` > `AutomationId+ControlType` > `Name+ControlType`)
2. State-based success verification (before/after evidence)
3. Centralized timeout/retry defaults
4. Circuit-breaker + error-bucketed retry policy
5. Correlation-id based logging for traceability

## Usage rule
- 레퍼런스는 "코드 그대로 도입"이 아니라 "패턴만 채택"한다.
- 우리 환경(WSL+Windows bridge)에 맞춰 안전 가드(락/쿨다운/상한)를 먼저 붙인다.
