#Requires AutoHotkey v2.0

if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(2000)
}

WinActivate("ahk_exe chrome.exe")
if !WinWaitActive("ahk_exe chrome.exe",,4) {
    ExitApp(2)
}
WinRestore("ahk_exe chrome.exe")
Sleep(300)

; Candidate points near Chrome toolbar extension area (right side)
points := [
    [A_ScreenWidth-145, 48],
    [A_ScreenWidth-120, 48],
    [A_ScreenWidth-95, 48],
    [A_ScreenWidth-170, 48],
    [A_ScreenWidth-145, 62],
    [A_ScreenWidth-120, 62],
    [A_ScreenWidth-95, 62]
]

for p in points {
    MouseMove(p[1], p[2], 0)
    Click()
    Sleep(350)
}

ExitApp(0)
