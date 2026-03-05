#Requires AutoHotkey v2.0
xOff := (A_Args.Length>=1)?Integer(A_Args[1]):145
yTop := (A_Args.Length>=2)?Integer(A_Args[2]):48
CoordMode("Mouse", "Screen")
if WinExist("ahk_exe chrome.exe") {
  WinGetPos(&wx,&wy,&ww,&wh,"ahk_exe chrome.exe")
  if (ww > 0) {
    x := wx + ww - xOff
    y := wy + yTop
    MouseMove(x,y,0)
    Click()
    Sleep(200)
    ExitApp(0)
  }
}
; fallback screen-right click
MouseMove(A_ScreenWidth - xOff, yTop, 0)
Click()
Sleep(200)
ExitApp(0)
