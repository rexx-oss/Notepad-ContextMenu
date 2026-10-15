# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator!"
    Exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "1. Installing Security Certificate..." -ForegroundColor Cyan
$certPath = Join-Path $ScriptDir "VanillaClassicNotepad.cer"
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null

Write-Host "2. Registering Signed MSIX Package..." -ForegroundColor Cyan
$msixPath = Join-Path $ScriptDir "NotepadMenu.msix"
Add-AppxPackage -Path $msixPath -ExternalLocation $ScriptDir

Write-Host "3. Restoring 'New -> Text Document' Menu..." -ForegroundColor Cyan
New-Item -Path "Registry::HKEY_CLASSES_ROOT\.txt" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\.txt" -Name "(Default)" -Value "txtfilelegacy"
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\.txt" -Name "Content Type" -Value "text/plain"
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\.txt" -Name "PerceivedType" -Value "text"

New-Item -Path "Registry::HKEY_CLASSES_ROOT\.txt\ShellNew" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\.txt\ShellNew" -Name "NullFile" -Value ""

New-Item -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy" -Name "(Default)" -Value "Text Document"
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy" -Name "FriendlyTypeName" -Value "@%SystemRoot%\system32\notepad.exe,-469"

New-Item -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy\DefaultIcon" -Name "(Default)" -Value "%SystemRoot%\system32\notepad.exe,0"

New-Item -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\txtfilelegacy\shell\open\command" -Name "(Default)" -Value '%SystemRoot%\system32\notepad.exe "%1"'

Write-Host "4. Restarting Windows Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force

Write-Host "`nInstallation successful!" -ForegroundColor Green
Write-Host "• 'Edit with Notepad' is active on native file types in Windows 11."
Write-Host "• 'New -> Text Document' is restored."
