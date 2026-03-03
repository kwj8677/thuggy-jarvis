# Fallback Trace Report — 2026-03-04

- generatedAt: 2026-03-04T04:03:35.127734
- sampleSize(meta rows): 1104

## Core action pass/fail

| action | pass/total | passRate | top fail reasons |
|---|---:|---:|---|
| chrome_l1_launch_uia.ps1 | 96/153 | 0.627 | nonzero_exit:55, timeout:2 |
| chrome_uia_pipeline.ps1 | 46/126 | 0.365 | nonzero_exit:80 |
| explorer_l2_pipeline_uia.ps1 | 20/23 | 0.870 | nonzero_exit:3 |
| relay_icon_target_train_uia.ps1 | 49/54 | 0.907 | nonzero_exit:5 |
| relay_permission_auto.ps1 | 0/6 | 0.000 | nonzero_exit:4, timeout:2 |
| relay_permission_grant_uia.ps1 | 1/19 | 0.053 | nonzero_exit:15, timeout:3 |
| relay_tabs_gate.ps1 | 18/49 | 0.367 | nonzero_exit:31 |
| session_gate.ps1 | 239/253 | 0.945 | nonzero_exit:14 |
| settings_l3_pipeline_uia.ps1 | 19/21 | 0.905 | nonzero_exit:2 |
| uia_ahk_cross_train.ps1 | 48/61 | 0.787 | nonzero_exit:13 |
| uia_ahk_cross_train_explorer.ps1 | 0/9 | 0.000 | nonzero_exit:9 |
| uia_ahk_cross_train_settings.ps1 | 0/9 | 0.000 | timeout:9 |

## Observations
- Stable: explorer/settings UIA pipelines, relay icon targeting, UIA↔AHK cross-train.
- Unstable: relay permission grant/auto and relay tabs gate (permission path + attach verification bottleneck).
- Policy impact: use strict fallback logging and force chain transitions, do not block on single tabs probe.
