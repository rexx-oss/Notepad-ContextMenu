# Run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator!"
    Exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "1. Installing Certificate..." -ForegroundColor Cyan
$certPath = Join-Path $ScriptDir "VanillaClassicNotepad.cer"
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$rootStore.Open("ReadWrite")
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)
$rootStore.Add($cert)
$rootStore.Close()

Write-Host "2. Registering Sparse Context Menu Package..." -ForegroundColor Cyan
$manifestPath = Join-Path $ScriptDir "AppxManifest.xml"
Add-AppxPackage -Register $manifestPath -ExternalLocation $ScriptDir

Write-Host "3. Restoring 'New -> Text Document' Context Menu..." -ForegroundColor Cyan
# Native Windows vanilla keys for .txt and ShellNew
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

Write-Host "4. Restarting Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force

Write-Host "`nDone! 'Edit with Notepad' and 'New -> Text Document' are now restored." -ForegroundColor Green
