#Requires AutoHotkey v2.0

Run("notepad.exe")

ok := false
Loop 6 {
    if WinWaitActive("ahk_exe notepad.exe",,2) {
        Send("Hello from OpenClaw WSL via AHK")
        ok := true
        break
    }
    Sleep(500)
}

if ok {
    ExitApp(0)
}

ExitApp(1)
