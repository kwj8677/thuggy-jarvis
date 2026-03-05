#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
CoordMode("Mouse", "Screen")
SetTimer(ForceExit, -7000)

ForceExit(*) {
    ExitApp(9)
}

; Click relay icon by window-relative offsets (more stable than absolute screen coords)
; Args: xOffsetFromRight yOffsetFromTop
xOff := 145
yTop := 48

if (A_Args.Length >= 1)
    xOff := Integer(A_Args[1])
if (A_Args.Length >= 2)
    yTop := Integer(A_Args[2])

if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(1800)
}

WinActivate("ahk_exe chrome.exe")
if !WinWaitActive("ahk_exe chrome.exe",,4)
    ExitApp(2)

WinRestore("ahk_exe chrome.exe")
Sleep(250)

WinGetPos(&wx, &wy, &ww, &wh, "ahk_exe chrome.exe")
if (ww <= 0)
    ExitApp(3)

cx := wx + ww - xOff
cy := wy + yTop
MouseMove(cx, cy, 0)
Click()
Sleep(400)
ExitApp(0)
