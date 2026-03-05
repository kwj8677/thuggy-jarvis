Start-Process 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
Start-Sleep -Seconds 2
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")]
  public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
"@
Get-Process chrome -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  ForEach-Object { [Win32]::ShowWindowAsync($_.MainWindowHandle, 3) | Out-Null }
