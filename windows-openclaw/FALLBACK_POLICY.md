# Windows Fallback Policy (authoritative)

## Priority Order
1. `windows-control` or `windows-uia-advanced` (UIA-based control first)
2. If failed, fallback to `midscene-computer-automation` (vision + learned actions)
3. If failed again, generate/execute AHK script for forced action (pixel/hotkey)

## Mandatory Logging
On every fallback transition, append this exact format:

`Fallback to [skill] because [reason]`

Examples:
- `Fallback to midscene-computer-automation because uia_target_not_found`
- `Fallback to ahk because midscene_confidence_low`

## Success Rule
Never mark success on click only. Success requires:
- state transition observed
- at least 2 evidence artifacts (UIA/CDP/screenshot/report)
