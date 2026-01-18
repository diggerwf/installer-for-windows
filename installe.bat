@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
:: Stelle sicher, dass der Link absolut korrekt ist!
set "REPO_URL=https://github.com/diggerwf/installer-for-windows.git"
set "BRANCH=beta-1"
set "START_FILE=start.bat"

:: Diese Befehle schalten JEDE Login-Abfrage hart aus
set "GIT_TERMINAL_PROMPT=0"
set "GCM_INTERACTIVE=never"
:: ---------------------

echo ===========================================
echo       Projekt-Installer (Hard No-Login)
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
    echo [+] Git wird via Winget installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:CLONE_REPO
echo [+] Wechsle in Zielordner...
cd /d "%TARGET_DIR%"

:: Ordner-Check: Wenn nicht leer, Unterordner erstellen
dir /a /b | findstr . >nul 2>&1
if %errorlevel% equ 0 (
    for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
    echo [!] Ordner nicht leer. Erstelle: !DIR_NAME!
    mkdir "!DIR_NAME!" 2>nul
    cd "!DIR_NAME!"
)

echo [+] Klone Projekt (Erzwungen Anonym)...
:: -c credential.helper= deaktiviert alle gespeicherten Passwoerter
:: --config core.askpass=true unterdrueckt externe Dialoge
git -c credential.helper= clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] FEHLER: Klonen ohne Login nicht moeglich!
    echo.
    echo GRUND 1: Das Repository ist PRIVAT.
    echo         (Private Repos gehen NIEMALS ohne Login/Token)
    echo GRUND 2: Die URL ist falsch (Tippfehler?).
    echo.
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
