#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
CoordMode("Mouse", "Screen")
SetTimer(ForceExit, -9000)

ForceExit(*) {
    ExitApp(9)
}

img := "\\wsl.localhost\Ubuntu\home\humil\.openclaw\media\inbound\file_13---2cd8b756-6548-4611-91e1-b5a9e0d2482b.jpg"

if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(2000)
}

WinActivate("ahk_exe chrome.exe")
if !WinWaitActive("ahk_exe chrome.exe",,4) {
    ExitApp(2)
}

WinRestore("ahk_exe chrome.exe")
Sleep(400)

found := false
x := 0
y := 0

; Try full-screen image search with small variation tolerance
try {
    ImageSearch(&x, &y, 0, 0, A_ScreenWidth, A_ScreenHeight, "*30 " img)
    found := true
} catch {
    found := false
}

if !found {
    ExitApp(1)
}

; Click center-ish of icon
MouseMove(x + 12, y + 12, 0)
Click()
Sleep(600)
ExitApp(0)
