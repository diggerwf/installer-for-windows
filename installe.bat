@echo off
setlocal enabledelayedexpansion

:: --- EINSTELLUNGEN ---
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"

:: Verhindert, dass Git ein Login-Fenster oeffnet
set GIT_TERMINAL_PROMPT=0
:: Verhindert das Aufpoppen des Git-Credential-Managers
set GCM_INTERACTIVE=never
:: ---------------------

echo ===========================================
echo       Projekt-Installer (No Popup)
echo ===========================================

:CHOOSE_FOLDER
echo [+] Bitte Ordner im Fenster waehlen...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Zielordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo [!] Abbruch: Kein Ordner gewaehlt.
    pause
    exit /b
)

:CHECK_GIT
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [+] Git wird installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:CLONE_REPO
echo [+] Wechsle in: "%TARGET_DIR%"
cd /d "%TARGET_DIR%"

:: Falls der Ordner nicht leer ist, erstelle einen Unterordner
dir /a /b | findstr . >nul 2>&1
if %errorlevel% equ 0 (
    for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
    echo [!] Ordner nicht leer. Nutze Unterordner: !DIR_NAME!
    mkdir "!DIR_NAME!" 2>nul
    cd "!DIR_NAME!"
)

echo [+] Klone Projekt (Anonym)...
:: Wir nutzen -c credential.provider=none um den Login-Manager komplett zu deaktivieren
git -c credential.provider=none clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] FEHLER: Klonen fehlgeschlagen.
    echo Mögliche Gründe: 
    echo 1. Das Repo ist PRIVAT (dann ist ein Login zwingend).
    echo 2. Die URL oben im Skript ist falsch.
    pause
    exit /b
)

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [+] Fertig. %START_FILE% nicht gefunden.
    pause
)
