#!/usr/bin/env bash
set -euo pipefail

# Run Windows Gemini CLI from WSL with a Windows cwd (avoid UNC warnings)
cmd.exe /C "cd /d C:\Users\humil && gemini $*"
