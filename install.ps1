# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "=============================================" -ForegroundColor DarkCyan
Write-Host "     Vanilla Classic Notepad Installer       " -ForegroundColor White
Write-Host "=============================================" -ForegroundColor DarkCyan

# Prompt user for Start Menu shortcut
$ans = Read-Host "Do you want to create a Start Menu shortcut for Notepad? (Y/N) [Default: Y]"
$createShortcut = ($ans -notmatch '^[Nn]')

Write-Host "`n1. Staging Classic Notepad Executable..." -ForegroundColor Cyan
Copy-Item "$env:SystemRoot\System32\notepad.exe" -Destination (Join-Path $ScriptDir "notepad.exe") -Force

Write-Host "2. Installing Certificate..." -ForegroundColor Cyan
$certPath = Join-Path $ScriptDir "VanillaClassicNotepad.cer"
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null

Write-Host "3. Registering Sparse Context Menu Package..." -ForegroundColor Cyan
$msixPath = Join-Path $ScriptDir "NotepadMenu.msix"
Add-AppxPackage -Path $msixPath -ExternalLocation $ScriptDir

Write-Host "4. Killing Ghost UWP Redirects (Fixes Permission Error)..." -ForegroundColor Cyan
# reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /v "UseFilter" /t REG_DWORD /d 0 /f
# reg delete "HKCR\Applications\notepad.exe\shell\open\command" /v "DelegateExecute" /f 2>$null
# reg delete "HKCR\txtfilelegacy\shell\open\command" /v "DelegateExecute" /f 2>$null
# reg delete "HKCR\Applications\notepad.exe" /v "NoOpenWith" /f 2>$null
# reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\notepad.exe" /f 2>$null
# reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.txt\UserChoice" /f 2>$null
# reg delete "HKCR\*\shell\Edit with Notepad" /f 2>$null
# Remove-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\notepad.exe" -Force -ErrorAction SilentlyContinue

Write-Host "5. Setting Classic Open Commands..." -ForegroundColor Cyan
# reg add 'HKCR\txtfilelegacy\shell\open\command' /ve /t REG_SZ /d 'C:\Windows\System32\notepad.exe "%1"' /f
# reg add 'HKCR\Applications\notepad.exe\shell\open\command' /ve /t REG_SZ /d 'C:\Windows\System32\notepad.exe "%1"' /f

Write-Host "6. Restoring 'New -> Text Document'..." -ForegroundColor Cyan
reg add 'HKCR\.txt' /ve /t REG_SZ /d 'txtfilelegacy' /f
reg add 'HKCR\.txt' /v 'Content Type' /t REG_SZ /d 'text/plain' /f
reg add 'HKCR\.txt' /v 'PerceivedType' /t REG_SZ /d 'text' /f
New-Item -Path "Registry::HKEY_CLASSES_ROOT\.txt\ShellNew" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\.txt\ShellNew" -Name "NullFile" -Value "" -Force

Write-Host "7. Setting Classic Document Icon..." -ForegroundColor Cyan
reg add 'HKCR\txtfilelegacy' /ve /t REG_SZ /d 'Text Document' /f
reg add 'HKCR\txtfilelegacy\DefaultIcon' /ve /t REG_SZ /d '%SystemRoot%\system32\imageres.dll,-102' /f
reg add 'HKCR\Applications\notepad.exe\DefaultIcon' /ve /t REG_SZ /d '%SystemRoot%\system32\imageres.dll,-102' /f

if ($createShortcut) {
    Write-Host "8. Creating Start Menu Shortcut for Notepad..." -ForegroundColor Cyan
    $wsh = New-Object -ComObject WScript.Shell
    $shortcutPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad.lnk"
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "$env:SystemRoot\System32\notepad.exe"
    $shortcut.WorkingDirectory = "$env:SystemRoot\System32"
    $shortcut.Description = "Notepad"
    $shortcut.IconLocation = "$env:SystemRoot\System32\notepad.exe,0"
    $shortcut.Save()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wsh) | Out-Null
}

Write-Host "9. Flushing Icon Cache & Restarting Explorer..." -ForegroundColor Cyan
taskkill /f /im explorer.exe 2>$null
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "`nAll done! Crisp high-res icons and working shortcut installed." -ForegroundColor Green
