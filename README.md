# Notepad-ContextMenu

Adds classic Notepad (notepad.exe) directly to the Windows 11 top-level modern context menu for text and script files. Restores "New -> Text Document", the classic document icon, and includes an optional Start Menu shortcut.

## Prerequisites
Windows 11 (build 22000 or newer).

## Build (GitHub Actions)
1. Go to Actions -> "Build Notepad-ContextMenu Package".
2. Click "Run workflow".
3. Download Notepad-ContextMenu.zip from Artifacts.

## Release (GitHub Actions)
1. Go to Actions -> "Release Notepad-ContextMenu".
2. Click "Run workflow" and enter the release tag (e.g. v1.0.0).

## Install
1. Extract Notepad-ContextMenu.zip.
2. Open PowerShell as Administrator in that folder:
   powershell -ExecutionPolicy Bypass -File .\install.ps1
3. Answer the setup prompts (LTSC check, Start Menu shortcut).
4. Delete the extracted folder after installation.

## Uninstall
Open PowerShell as Administrator in that folder:
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
