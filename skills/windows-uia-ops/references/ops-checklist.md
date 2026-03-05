# Ops Checklist

## Preflight
- Confirm windows node connected
- Confirm chrome default profile only
- Confirm gateway/cdp reachable

## Execution
- session_gate -> stage pipeline -> verify evidence
- If failure: classify by taxonomy before retry

## Verification priority
1. state text/attached status
2. real connection probe (tabs/snapshot)
3. diagnostic port checks

## Relay Test Sequence (validated)
1. `chrome_uia_pipeline.ps1`
2. `relay_icon_target_train_uia.ps1`
3. `relay_tabs_gate.ps1` (PASS if `okByTabs` OR `okByAttached`)
4. Save report paths in training archive

## UIA↔AHK Cross Training (new)
1. Run `uia_ahk_cross_train.ps1` (Chrome)
2. Run `uia_ahk_cross_train_windows.ps1 -App explorer|settings` (Windows apps)
3. Use UIA-picked target center as AHK click coordinate
4. Verify click by UIA hit/focus checks
5. Keep only success samples for calibration updates

## Promotion rule
- stable=true only if successRate>=0.9 and total>=10
