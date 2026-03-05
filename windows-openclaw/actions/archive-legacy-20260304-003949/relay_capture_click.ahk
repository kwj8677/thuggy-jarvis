#Requires AutoHotkey v2.0

logFile := "C:\openclaw\logs\relay-capture.log"
FileAppend("capture_start " A_Now "`n", logFile, "UTF-8")

if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(1500)
}
WinActivate("ahk_exe chrome.exe")
WinWaitActive("ahk_exe chrome.exe",,4)
WinGetPos(&wx,&wy,&ww,&wh,"ahk_exe chrome.exe")

ToolTip("Relay 아이콘을 한 번 클릭하세요 (30초)")
start := A_TickCount
captured := false
x := 0, y := 0
while (A_TickCount - start < 30000) {
    if GetKeyState("LButton", "P") {
        MouseGetPos(&x,&y)
        captured := true
        break
    }
    Sleep(30)
}
ToolTip()

if !captured {
    FileAppend("capture_timeout`n", logFile, "UTF-8")
    ExitApp(1)
}

xOff := (wx + ww) - x
yTop := y - wy

; ROI guard: only accept clicks in top toolbar band
if (yTop < 15 || yTop > 120 || xOff < 60 || xOff > 320) {
    FileAppend("capture_reject_out_of_roi click_x=" x " click_y=" y " xOff=" xOff " yTop=" yTop "`n", logFile, "UTF-8")
    ExitApp(4)
}

FileAppend("click_x=" x " click_y=" y " win_x=" wx " win_y=" wy " win_w=" ww " xOff=" xOff " yTop=" yTop "`n", logFile, "UTF-8")

; save quick calibration JSON
json := "{`"xOffsetFromRight`":" xOff ",`"yOffsetFromTop`":" yTop "}"
FileDelete("C:\openclaw\relay-last-offset.json")
FileAppend(json, "C:\openclaw\relay-last-offset.json", "UTF-8")

ExitApp(0)
