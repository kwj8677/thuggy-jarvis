#Requires AutoHotkey v2.0
Run("notepad.exe")
if WinWaitActive("ahk_exe notepad.exe",,3) {
    Send("Hello from OpenClaw WSL via AHK")
    ExitApp(0)
}
ExitApp(1)
