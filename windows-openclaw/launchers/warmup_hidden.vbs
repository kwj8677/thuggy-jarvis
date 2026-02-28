Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "wsl -d Ubuntu --exec bash -lc ""echo warmup_ok""", 0, False
