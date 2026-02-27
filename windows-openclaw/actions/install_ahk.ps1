if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Write-Error "Chocolatey not found"
  exit 2
}
choco install autohotkey -y
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output "autohotkey_installed_or_updated"