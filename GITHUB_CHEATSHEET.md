# GitHub 초간단 치트시트 (humil 전용)

## 0) 지금 상태 확인
```bash
git status -sb
```

## 1) 작업 저장(커밋)
```bash
git add .
git commit -m "작업 내용 한 줄 요약"
```

## 2) GitHub로 백업(푸시)
```bash
git push
```

## 3) 최신 내용 가져오기
```bash
git pull --rebase
```

## 4) 최근 기록 보기
```bash
git log --oneline -n 10
```

## 5) 실수했을 때 (안전)
### (A) 아직 커밋 안 한 수정 되돌리기
```bash
git restore <파일명>
```

### (B) 마지막 커밋만 취소(기록은 남기고 반대로 되돌림)
```bash
git revert HEAD
```

---

## 네 기본 규칙(안정성 우선)
1. 시스템 민감 설정은 바꾸기 전 반드시 확인
2. 큰 변경 전에는 먼저 커밋으로 현재 상태 저장
3. 기능 추가보다 "안정적으로 유지"를 우선

---

## 오늘 기준 현재 브랜치
- main (origin/main 추적)
