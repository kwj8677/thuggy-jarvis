# Failure Taxonomy

- session_gate_failed
- session_gate_unstable
- launch_profile_mismatch
- trigger_miss_or_timeout
- relay_attach_no_match
- relay_invoke_missing
- relay_permission_not_visible
- verification_false_negative

## Mapping
- relay_attach_no_match -> structural matcher 강화(toolbar/tree)
- relay_invoke_missing -> click fallback + state re-check
- relay_permission_not_visible -> desktop-root + MenuItem/Button scan
- verification_false_negative -> multi-source evidence OR-logic

## Observed Exit Codes (2026-03-04 trace)
- `61`: relay_tabs_gate fail (tabs/attached both false)
- `183`: relay permission allow-button not found
- `184`: relay_permission_auto failed after fallback chain
- `124`: timeout (action exceeded timeoutSec)
- `131/132/171`: chrome/uia targeting instability classes

## Required fallback log line
`Fallback to [skill] because [reason]`
