#!/usr/bin/env bash
set -euo pipefail

# WSL -> Windows PowerShell guarded relay attach (direct script execution)
WIN_FILE=$(wslpath -w /home/humil/.openclaw/workspace/windows-openclaw/actions/relay_attach_guarded_uia.ps1)
/home/humil/.openclaw/workspace/scripts/psw "powershell.exe -NoProfile -ExecutionPolicy Bypass -File '$WIN_FILE' -StrictFailFast -MaxAttempts 1 -TotalTimeoutSec 60 -AttachTimeoutSec 35 -VerifyTimeoutSec 20"