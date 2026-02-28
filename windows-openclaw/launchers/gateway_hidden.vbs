Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "wsl -d Ubuntu --exec bash -lc ""openclaw gateway""", 0, False
