#Requires AutoHotkey v2.0

; Try to activate Chrome and click near extension toolbar area where Relay icon usually sits.
if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(1500)
}

WinActivate("ahk_exe chrome.exe")
if !WinWaitActive("ahk_exe chrome.exe",,3) {
    ExitApp(2)
}

; Ensure window is not minimized
WinRestore("ahk_exe chrome.exe")
Sleep(400)

; Approximate click near top-right extension icon row
; This is heuristic and may not work on all layouts/scales.
MouseMove(A_ScreenWidth - 120, 48, 0)
Click()
Sleep(500)
Click() ; second click to toggle if needed

ExitApp(0)
