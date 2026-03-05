# WORKFLOW_AUTO

이 파일은 compaction/reset 이후에도 작업 맥락을 복구하기 위한 자동 운영 기준이다.

## Default Operating Skill
- `skills/windows-uia-ops/SKILL.md`

## Non-forgetful Loop
1. `memory/최근날짜.md` 읽기
2. `training-runs/uia-master-dataset.json` 확인
3. 현재 병목 1개만 선택해서 해결
4. 결과를 로그/메모리에 append

## First-Principles Priority
- 클릭 성공 금지, 상태전이+증거만 성공
- 단일 게이트 false negative 금지(다중 증거 OR)
- Chrome 기본 프로필 강제

## Current primary blocker
- L5 relay verification alignment (attached-state vs tabs-gate)
