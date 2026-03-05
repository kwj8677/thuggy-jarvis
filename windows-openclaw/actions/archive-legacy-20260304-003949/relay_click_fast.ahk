#Requires AutoHotkey v2.0
CoordMode("Mouse", "Screen")
pts := [[120,48],[145,48],[95,48],[170,48],[120,62],[145,62],[95,62],[120,78]]
for p in pts {
  x := A_ScreenWidth - p[1]
  y := p[2]
  MouseMove(x,y,0)
  Click()
  Sleep(220)
}
ExitApp(0)
