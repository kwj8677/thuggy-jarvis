param(
  [string]$App = "chrome",
  [int]$X = 0,
  [int]$Y = 0,
  [string]$Profile = "default"
)
$ErrorActionPreference='Stop'
$learn='C:\openclaw\gui-learn.json'
if(!(Test-Path $learn)){ '{"profiles":{"default":{"window":"chrome","clickPoints":[],"lastSuccess":null}}}' | Out-File $learn -Encoding utf8 }
$j=Get-Content $learn -Raw | ConvertFrom-Json
if(-not $j.profiles.$Profile){ $j.profiles | Add-Member -NotePropertyName $Profile -NotePropertyValue ([pscustomobject]@{window=$App;clickPoints=@();lastSuccess=$null}) }
$p=$j.profiles.$Profile

# choose point: explicit > lastSuccess > first known
if($X -le 0 -or $Y -le 0){
  if($p.lastSuccess){ $X=[int]$p.lastSuccess.x; $Y=[int]$p.lastSuccess.y }
  elseif($p.clickPoints.Count -gt 0){ $X=[int]$p.clickPoints[0].x; $Y=[int]$p.clickPoints[0].y }
}

$args = "`"$App`" $X $Y"
& C:\openclaw\run.ps1 -Action gui_click_engine.ahk -ActionArgs $args -TimeoutSec 15 | Out-Null
$rc = $LASTEXITCODE
if($rc -eq 0 -and $X -gt 0 -and $Y -gt 0){
  $p.lastSuccess = [pscustomobject]@{x=$X;y=$Y;ts=(Get-Date).ToString('o')}
  $exists = $false
  foreach($pt in $p.clickPoints){ if($pt.x -eq $X -and $pt.y -eq $Y){$exists=$true;break} }
  if(-not $exists){ $p.clickPoints += [pscustomobject]@{x=$X;y=$Y;ok=1} }
  $j | ConvertTo-Json -Depth 8 | Out-File $learn -Encoding utf8
}
Write-Output "GUI_ENGINE_RC=$rc X=$X Y=$Y"
exit $rc
