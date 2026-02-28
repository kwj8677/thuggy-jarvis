$ErrorActionPreference = 'Continue'
Get-Date -Format o
Write-Output "---"
Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,LastBootUpTime
Write-Output "---"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name,Id,CPU
