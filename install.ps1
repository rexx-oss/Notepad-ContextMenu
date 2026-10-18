# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }

Write-Host "=============================================" -ForegroundColor DarkCyan
Write-Host "         Notepad-ContextMenu Installer       " -ForegroundColor White
Write-Host "=============================================" -ForegroundColor DarkCyan

$versionChoice = Read-Host "Select Windows 11 version: [1] LTSC, [2] Not LTSC"
$confirm = Read-Host "Enter confirmation code '123' to proceed"
if ($confirm -ne '123') {
    Write-Warning "Incorrect confirmation code. Operation cancelled."
    Exit
}
$isLtsc = ($versionChoice -eq '1' -or $versionChoice -match '^[Yy]' -or $versionChoice -match 'ltsc')

$createShortcut = $false
if (-not $isLtsc) {
    $ans = Read-Host "Do you want to create a Start Menu shortcut for Notepad? (Y/N) [Default: Y]"
    $createShortcut = ($ans -notmatch '^[Nn]')
}

Write-Host "`n1. Installing Certificate..." -ForegroundColor Cyan
$certPath = Join-Path $ScriptDir "Notepad-ContextMenu.cer"
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null

Write-Host "2. Installing directly to WindowsApps..." -ForegroundColor Cyan
$msixPath = Join-Path $ScriptDir "NotepadMenu.msix"
Add-AppxPackage -Path $msixPath

if ($isLtsc) {
    Write-Host "`nInstalled cleanly inside C:\Program Files\WindowsApps\Notepad-ContextMenu_...!" -ForegroundColor Green
    Write-Host "You can now safely delete the downloaded folder." -ForegroundColor Yellow
    Exit
}

Write-Host "3. Restoring 'New -> Text Document'..." -ForegroundColor Cyan
reg add 'HKCR\.txt' /ve /t REG_SZ /d 'txtfilelegacy' /f
reg add 'HKCR\.txt' /v 'Content Type' /t REG_SZ /d 'text/plain' /f
reg add 'HKCR\.txt' /v 'PerceivedType' /t REG_SZ /d 'text' /f
New-Item -Path "Registry::HKEY_CLASSES_ROOT\.txt\ShellNew" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\.txt\ShellNew" -Name "NullFile" -Value "" -Force

Write-Host "4. Setting Classic Document Icon..." -ForegroundColor Cyan
reg add 'HKCR\txtfilelegacy' /ve /t REG_SZ /d 'Text Document' /f
reg add 'HKCR\txtfilelegacy\DefaultIcon' /ve /t REG_SZ /d '%SystemRoot%\system32\imageres.dll,-102' /f
reg add 'HKCR\Applications\notepad.exe\DefaultIcon' /ve /t REG_SZ /d '%SystemRoot%\system32\imageres.dll,-102' /f

if ($createShortcut) {
    Write-Host "5. Creating Start Menu Shortcut for Notepad..." -ForegroundColor Cyan
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

Write-Host "`nInstalled cleanly inside C:\Program Files\WindowsApps\Notepad-ContextMenu_...!" -ForegroundColor Green
Write-Host "You can now safely delete the downloaded folder." -ForegroundColor Yellow
