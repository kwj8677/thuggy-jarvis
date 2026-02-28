# Session Logs (raw)

- 파일명 규칙: `<session-id>.md`
- 목적: 대화 원문/실험 로그를 **append-only**로 저장
- 원칙: 수정 최소화, 삭제 금지 (정정은 새 줄로)

## 한 줄 기록 포맷(권장)

```md
- [2026-02-28T21:40:00+09:00] decision|change|failure :: 내용
```

## 분류 기준

- `decision`: 의사결정 확정
- `change`: 설정/스크립트/운영 변경
- `failure`: 실패 원인/재현 조건/완화 방법

## 금지

- 민감정보(실키/토큰) 평문 저장 금지
- 좌표/실험값은 여기 말고 JSON(예: `windows-openclaw/relay-calibration.json`) 사용
