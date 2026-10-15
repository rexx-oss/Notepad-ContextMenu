# Notepad-ContextMenu

Adds classic Notepad (`notepad.exe`) to the Windows 11 modern context menu for text and script files, restores "New -> Text Document", fixes the permission error caused by uninstalled UWP Notepad, and restores the classic document icon.

## Build (GitHub Actions)
1. Go to the Actions tab in your repository.
2. Select "Build Notepad-ContextMenu Package" -> click "Run workflow".
3. Download `Notepad-ContextMenu.zip` from Artifacts.

## Install
1. Extract `Notepad-ContextMenu.zip`.
2. Open PowerShell as Administrator in that folder:
   powershell -ExecutionPolicy Bypass -File .\install.ps1
3. Choose Y or N when prompted for the Start Menu shortcut.
4. Delete the extracted folder after installation.

## Uninstall
Open PowerShell as Administrator in that folder:
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
