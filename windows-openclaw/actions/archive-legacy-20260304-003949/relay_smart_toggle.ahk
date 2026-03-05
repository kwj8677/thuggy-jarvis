#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
CoordMode("Mouse", "Screen")
SetTimer(ForceExit, -9000)

ForceExit(*) {
    ExitApp(9)
}

cfgPath := "C:\openclaw\relay-calibration.json"
if !FileExist(cfgPath) {
    ExitApp(3)
}

json := FileRead(cfgPath, "UTF-8")
; minimal JSON parse via regex for needed values
img := RegExReplace(json, ".*\"imagePath\"\s*:\s*\"([^\"]+)\".*", "$1", "s")
var := RegExReplace(json, ".*\"imageVariation\"\s*:\s*([0-9]+).*", "$1", "s")
if (img = json || var = json) {
    ExitApp(4)
}

if !WinExist("ahk_exe chrome.exe") {
    Run("chrome.exe")
    Sleep(2000)
}

WinActivate("ahk_exe chrome.exe")
if !WinWaitActive("ahk_exe chrome.exe",,4) {
    ExitApp(2)
}
WinRestore("ahk_exe chrome.exe")
Sleep(250)

found := false
x := 0, y := 0

; ROI near extension toolbar (top-right)
x1 := A_ScreenWidth - 260
y1 := 20
x2 := A_ScreenWidth - 20
y2 := 110

try {
    ImageSearch(&x, &y, x1, y1, x2, y2, "*" var " " img)
    found := true
} catch {
    found := false
}

if (found) {
    MouseMove(x + 10, y + 10, 0)
    Click()
    Sleep(450)
    ExitApp(0)
}

; fallback candidate clicks
points := [
    [A_ScreenWidth-145, 48],[A_ScreenWidth-120, 48],[A_ScreenWidth-95, 48],[A_ScreenWidth-170, 48],
    [A_ScreenWidth-145, 62],[A_ScreenWidth-120, 62],[A_ScreenWidth-95, 62]
]
for p in points {
    MouseMove(p[1], p[2], 0)
    Click()
    Sleep(250)
}

ExitApp(0)
