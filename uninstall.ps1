# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

Write-Host "1. Removing Package from WindowsApps..." -ForegroundColor Cyan
Get-AppxPackage notepad-contextmenu | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "2. Removing Security Certificate..." -ForegroundColor Cyan
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$rootStore.Open("ReadWrite")
$certs = $rootStore.Certificates | Where-Object { $_.Subject -like "*CN=notepad-contextmenu*" }
foreach ($cert in $certs) {
    $rootStore.Remove($cert)
}
$rootStore.Close()

Write-Host "3. Removing Start Menu Shortcut..." -ForegroundColor Cyan
Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad.lnk" -Force -ErrorAction SilentlyContinue

Write-Host "4. Reverting Registry & IFEO Redirects..." -ForegroundColor Cyan
# reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /f 2>$null
# reg delete "HKCR\*\shell\Edit with Notepad" /f 2>$null
# reg delete "HKCR\txtfilelegacy" /f 2>$null
# reg delete "HKCR\Applications\notepad.exe\DefaultIcon" /f 2>$null
# reg delete "HKCU\Software\Classes\txtfilelegacy" /f 2>$null
# reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.txt\UserChoice" /f 2>$null

Write-Host "5. Flushing Icon Cache & Restarting Explorer..." -ForegroundColor Cyan
taskkill /f /im explorer.exe 2>$null
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "`nUninstalled successfully! System reverted." -ForegroundColor Green
