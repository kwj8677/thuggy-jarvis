#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

SetTitleMatchMode(2)

outPath := "C:\openclaw\logs\notepad-l1-output.txt"
marker := "L1TRAINMARKER-" A_Now
payload := marker "`r`nFirst-principles Windows GUI training pass.`r`n"

Run("notepad.exe \"" outPath "\"")
if !WinWaitActive("ahk_exe notepad.exe",,6) {
    ExitApp(11)
}

Sleep(300)
A_Clipboard := payload
Sleep(120)
SendInput("^a")
Sleep(80)
SendInput("^v")
Sleep(150)
SendInput("^s")
Sleep(300)

; close notepad
SendInput("!{F4}")

ExitApp(0)
