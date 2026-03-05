$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$runId=(Get-Date).ToString('yyyyMMdd-HHmmss')
$logDir='C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$report=Join-Path $logDir ("$runId-relay-permission-grant-uia-report.json")

function Save($ok,$reason,$data){
  [pscustomobject]@{ok=$ok;reason=$reason;timestamp=(Get-Date).ToString('o');data=$data} |
    ConvertTo-Json -Depth 12 | Out-File -FilePath $report -Encoding utf8
  Write-Output ("RELAY_PERMISSION_GRANT_UIA_REPORT="+$report)
}

# 1) ensure relay bubble opens
& C:\openclaw\run.ps1 -Action relay_icon_target_train_uia.ps1 -TimeoutSec 20 | Out-Null
Start-Sleep -Milliseconds 500

$desktop=[System.Windows.Automation.AutomationElement]::RootElement
$types=@('Button','MenuItem')
$allowPattern='^(허용|항상 허용|Allow|Always allow|On this site)$'
$accessHint='OpenClaw Browser Relay|site access|사이트 액세스|이 사이트의 액세스 권한'

$seen=@()
for($r=0;$r -lt 6;$r++){
  foreach($t in $types){
    $ct=[System.Windows.Automation.ControlType]::$t
    $cond=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty,$ct)
    $els=$desktop.FindAll([System.Windows.Automation.TreeScope]::Descendants,$cond)
    for($i=0;$i -lt $els.Count;$i++){
      $e=$els.Item($i)
      $n=[string]$e.Current.Name
      if(-not [string]::IsNullOrWhiteSpace($n)){ $seen += ($t+':'+$n) }
      if($n -match $allowPattern){
        # optional context check: nearby text in parent subtree
        $p=[System.Windows.Automation.TreeWalker]::ControlViewWalker.GetParent($e)
        $ctx=''
        if($p){ $ctx=[string]$p.Current.Name }
        $inv=$null
        if($e.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern,[ref]$inv)){
          $inv.Invoke(); Start-Sleep -Milliseconds 700
          Save $true 'ok' @{clicked=$n;type=$t;context=$ctx;round=$r}
          exit 0
        }
      }
    }
  }
  Start-Sleep -Milliseconds 450
}

Save $false 'allow_button_not_found' @{seenSample=@($seen|Select-Object -Unique -First 60)}
exit 183
