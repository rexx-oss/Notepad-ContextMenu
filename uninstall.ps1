# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

Write-Host "1. Removing Sparse MSIX Package..." -ForegroundColor Cyan
Get-AppxPackage VanillaClassicNotepad | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "2. Removing Security Certificate from Trusted Root..." -ForegroundColor Cyan
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$rootStore.Open("ReadWrite")
$certs = $rootStore.Certificates | Where-Object { $_.Subject -like "*CN=VanillaClassicNotepad*" }
foreach ($cert in $certs) {
    $rootStore.Remove($cert)
}
$rootStore.Close()

Write-Host "3. Reverting Registry & IFEO Redirects..." -ForegroundColor Cyan
# Remove the custom IFEO rule for notepad.exe
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /f 2>$null

# Remove any custom context menu shell verbs
reg delete "HKCR\*\shell\Edit with Notepad" /f 2>$null

# Remove custom txtfilelegacy entries
reg delete "HKCR\txtfilelegacy" /f 2>$null
reg delete "HKCR\Applications\notepad.exe\DefaultIcon" /f 2>$null
reg delete "HKCU\Software\Classes\txtfilelegacy" /f 2>$null

# Clean up UserChoice for .txt so Windows can cleanly bind to whatever app you choose next
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.txt\UserChoice" /f 2>$null

Write-Host "4. Flushing Icon Cache & Restarting Windows Explorer..." -ForegroundColor Cyan
taskkill /f /im explorer.exe 2>$null
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "`nComplete! Everything has been restored to default." -ForegroundColor Green
