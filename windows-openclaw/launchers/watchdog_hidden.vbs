Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "pwsh.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\temp\openclaw-ops\oc-watchdog.ps1", 0, False
