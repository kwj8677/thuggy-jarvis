#Requires AutoHotkey v2.0

logFile := "C:\openclaw\logs\relay-attach-trace.log"
FileAppend("--- relay_attach_train start " A_Now " ---`n", logFile, "UTF-8")

if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(2000)
    FileAppend("chrome launched`n", logFile, "UTF-8")
}

WinActivate("ahk_exe chrome.exe")
if !WinWaitActive("ahk_exe chrome.exe",,4) {
    FileAppend("chrome activate fail`n", logFile, "UTF-8")
    ExitApp(2)
}
WinRestore("ahk_exe chrome.exe")
Sleep(200)

; window-relative candidate clicks (x offset from right, y from top)
pts := [[145,48],[120,48],[95,48],[170,48],[145,62],[120,62],[95,62]]
WinGetPos(&wx,&wy,&ww,&wh,"ahk_exe chrome.exe")

for p in pts {
    x := wx + ww - p[1]
    y := wy + p[2]
    MouseMove(x,y,0)
    Click()
    FileAppend("click x=" x " y=" y " off=" p[1] "," p[2] "`n", logFile, "UTF-8")
    Sleep(350)
}

FileAppend("relay_attach_train end`n", logFile, "UTF-8")
ExitApp(0)
