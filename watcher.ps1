while ($true) {
    git -C "C:\JarvisRepo" pull
    $cmds=Get-ChildItem "C:\JarvisRepo\commands\*.json" -ErrorAction SilentlyContinue
    foreach ($c in $cmds) {
        try {
            $json=Get-Content $c.FullName | ConvertFrom-Json
            $logPath="C:\JarvisRepo\logs\$(Get-Date -Format yyyyMMdd-HHmmss)-$($c.BaseName).log"
            switch ($json.type) {
                "ECHO" {
                    "ECHO: $($json.message)" | Out-File $logPath
                }
                "RUN" {
                    Invoke-Expression $json.command 2>&1 | Out-File $logPath
                }
                default {
                    "Unknown command type: $($json.type)" | Out-File $logPath
                }
            }
        } catch {
            $_ | Out-File "C:\JarvisRepo\logs\error-$(Get-Date -Format yyyyMMdd-HHmmss).log"
        }
        Remove-Item $c.FullName
    }
    git -C "C:\JarvisRepo" add .
    git -C "C:\JarvisRepo" commit -m "Jarvis log update $(Get-Date)" --allow-empty
    git -C "C:\JarvisRepo" push
    Start-Sleep -Seconds 10
}
