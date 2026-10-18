# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

Write-Host "1. Removing Package from WindowsApps..." -ForegroundColor Cyan
Get-AppxPackage Notepad-ContextMenu | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "2. Removing Security Certificate..." -ForegroundColor Cyan
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$rootStore.Open("ReadWrite")
$certs = $rootStore.Certificates | Where-Object { $_.Subject -like "*CN=rexx*" }
foreach ($cert in $certs) {
    $rootStore.Remove($cert)
}
$rootStore.Close()

Write-Host "3. Removing Start Menu Shortcut..." -ForegroundColor Cyan
Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad.lnk" -Force -ErrorAction SilentlyContinue

Write-Host "`nUninstalled successfully! System reverted." -ForegroundColor Green
