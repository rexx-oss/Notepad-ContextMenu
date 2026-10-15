# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "1. Installing Certificate..." -ForegroundColor Cyan
$certPath = Join-Path $ScriptDir "VanillaClassicNotepad.cer"
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null

Write-Host "2. Registering Sparse Context Menu Package..." -ForegroundColor Cyan
$msixPath = Join-Path $ScriptDir "NotepadMenu.msix"
Add-AppxPackage -Path $msixPath -ExternalLocation $ScriptDir

Write-Host "3. Killing Ghost UWP Redirects (Fixes Permission Error)..." -ForegroundColor Cyan
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /v "UseFilter" /t REG_DWORD /d 0 /f
reg delete "HKCR\Applications\notepad.exe\shell\open\command" /v "DelegateExecute" /f 2>$null
reg delete "HKCR\txtfilelegacy\shell\open\command" /v "DelegateExecute" /f 2>$null
reg delete "HKCR\Applications\notepad.exe" /v "NoOpenWith" /f 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\notepad.exe" /f 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.txt\UserChoice" /f 2>$null
Remove-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\notepad.exe" -Force -ErrorAction SilentlyContinue

# Clean up universal wildcard so unrelated files (.mp4, .exe, .zip) don't get the menu
reg delete "HKCR\*\shell\Edit with Notepad" /f 2>$null

Write-Host "4. Setting Classic Open Commands..." -ForegroundColor Cyan
reg add 'HKCR\txtfilelegacy\shell\open\command' /ve /t REG_SZ /d 'C:\Windows\System32\notepad.exe "%1"' /f
reg add 'HKCR\Applications\notepad.exe\shell\open\command' /ve /t REG_SZ /d 'C:\Windows\System32\notepad.exe "%1"' /f

Write-Host "5. Restoring 'New -> Text Document'..." -ForegroundColor Cyan
reg add 'HKCR\.txt' /ve /t REG_SZ /d 'txtfilelegacy' /f
reg add 'HKCR\.txt' /v 'Content Type' /t REG_SZ /d 'text/plain' /f
reg add 'HKCR\.txt' /v 'PerceivedType' /t REG_SZ /d 'text' /f
reg add 'HKCR\.txt\ShellNew' /f /v 'NullFile' /t REG_SZ /d ''

Write-Host "6. Setting Classic Document Icon..." -ForegroundColor Cyan
reg add 'HKCR\txtfilelegacy' /ve /t REG_SZ /d 'Text Document' /f
reg add 'HKCR\txtfilelegacy\DefaultIcon' /ve /t REG_SZ /d '%SystemRoot%\system32\imageres.dll,-102' /f
reg add 'HKCR\Applications\notepad.exe\DefaultIcon' /ve /t REG_SZ /d '%SystemRoot%\system32\imageres.dll,-102' /f

Write-Host "7. Flushing Icon Cache & Restarting Explorer..." -ForegroundColor Cyan
taskkill /f /im explorer.exe 2>$null
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "`nAll done! Updated to 'Notepad' with native icons and restricted to related files." -ForegroundColor Green
