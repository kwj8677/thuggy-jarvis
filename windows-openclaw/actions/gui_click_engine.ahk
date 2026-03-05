#Requires AutoHotkey v2.0
; Args: appName x y
app := (A_Args.Length>=1)?A_Args[1]:"chrome"
x := (A_Args.Length>=2)?Integer(A_Args[2]):0
y := (A_Args.Length>=3)?Integer(A_Args[3]):0

exe := app="chrome" ? "chrome.exe" : app
if !WinExist("ahk_exe " exe) {
    Run(exe)
    Sleep(1500)
}
WinActivate("ahk_exe " exe)
if !WinWaitActive("ahk_exe " exe,,4)
    ExitApp(2)
WinRestore("ahk_exe " exe)
Sleep(150)
if (x>0 && y>0) {
    MouseMove(x,y,0)
    Click()
    ExitApp(0)
}
ExitApp(1)
