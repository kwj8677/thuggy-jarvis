# Continuous Improvement Loop (fixed)

## One cycle
1. Run batch (default 10)
2. Aggregate success/failure from reports
3. Classify failures by taxonomy
4. Patch skill rules/scripts for top-1 blocker only
5. Re-run same batch

## Stable promotion
- passRate >= 0.90
- totalRuns >= 10
- no critical regressions in session_gate/chrome_uia

## Reporting format
- batch size, pass, fail, passRate
- top failure causes
- exact changed files
- next single blocker
