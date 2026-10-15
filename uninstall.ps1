if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run as Administrator!"
    Exit
}

Write-Host "Removing Sparse Package..." -ForegroundColor Cyan
Get-AppxPackage VanillaClassicNotepad | Remove-AppxPackage

Stop-Process -Name explorer -Force
Write-Host "Uninstalled successfully." -ForegroundColor Green
