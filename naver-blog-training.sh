#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-/home/humil/.openclaw/workspace/training-runs}"
TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$OUT_DIR/naver-$TS"
mkdir -p "$RUN_DIR"

log(){ echo "[$(date +%H:%M:%S)] $*"; }

# test payload
TITLE="[테스트] agent-browser 작성 흐름 점검 $TS"
BODY="자동화 테스트 본문입니다.\n\n- 경로: 열기 → 입력 → 임시저장 확인\n- 시간: $(date)\n"

log "1) 네이버 블로그 글쓰기 페이지 오픈"
agent-browser open "https://blog.naver.com/PostWriteForm.naver" >"$RUN_DIR/01-open.txt" || true

log "2) 현재 URL/타이틀 수집"
agent-browser get url >"$RUN_DIR/url-1.txt" || true
agent-browser get title >"$RUN_DIR/title-1.txt" || true
URL1="$(cat "$RUN_DIR/url-1.txt" 2>/dev/null || true)"

# 로그인 필요 분기
if echo "$URL1" | grep -Eqi "nidlogin|login|signin"; then
  log "로그인 필요 상태 감지"
  cat >"$RUN_DIR/report.json" <<JSON
{
  "pass": false,
  "stage": "login_required",
  "url": $(printf '%s' "$URL1" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))'),
  "message": "네이버 로그인 세션이 필요합니다."
}
JSON
  agent-browser screenshot "$RUN_DIR/login-required.png" >"$RUN_DIR/shot-login.txt" || true
  echo "$RUN_DIR"
  exit 0
fi

log "3) 에디터 렌더 대기"
agent-browser wait 3000 >"$RUN_DIR/03-wait.txt" || true
agent-browser snapshot >"$RUN_DIR/snapshot-before.txt" || true

# 제목 입력 시도 (여러 선택자 fallback)
log "4) 제목 입력 시도"
set +e
agent-browser fill "textarea[placeholder*='제목']" "$TITLE" >"$RUN_DIR/04-title-a.txt" 2>&1
RC=$?
if [ $RC -ne 0 ]; then
  agent-browser click "text=제목" >"$RUN_DIR/04-title-b-click.txt" 2>&1
  agent-browser keyboard inserttext "$TITLE" >"$RUN_DIR/04-title-b-type.txt" 2>&1
fi
set -e

# 본문 입력 시도
log "5) 본문 입력 시도"
set +e
agent-browser click "[contenteditable='true']" >"$RUN_DIR/05-body-click-a.txt" 2>&1
RC=$?
if [ $RC -ne 0 ]; then
  agent-browser click "role=textbox" >"$RUN_DIR/05-body-click-b.txt" 2>&1
fi
agent-browser keyboard inserttext "$BODY" >"$RUN_DIR/05-body-type.txt" 2>&1
set -e

# 임시저장 시도
log "6) 임시저장 버튼 클릭 시도"
set +e
agent-browser click "text=임시저장" >"$RUN_DIR/06-save-a.txt" 2>&1
RC=$?
if [ $RC -ne 0 ]; then
  agent-browser click "text=저장" >"$RUN_DIR/06-save-b.txt" 2>&1
fi
set -e

log "7) 상태 확인"
agent-browser wait 2000 >"$RUN_DIR/07-wait-after-save.txt" || true
agent-browser get url >"$RUN_DIR/url-2.txt" || true
agent-browser snapshot >"$RUN_DIR/snapshot-after.txt" || true
agent-browser screenshot "$RUN_DIR/result.png" >"$RUN_DIR/08-shot.txt" || true

PASS=false
if grep -E "임시저장|저장|Draft|작성" "$RUN_DIR/snapshot-after.txt" >/dev/null 2>&1; then
  PASS=true
fi

cat >"$RUN_DIR/report.json" <<JSON
{
  "pass": $PASS,
  "stage": "editor_flow_attempted",
  "runDir": $(printf '%s' "$RUN_DIR" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')
}
JSON

echo "$RUN_DIR"
