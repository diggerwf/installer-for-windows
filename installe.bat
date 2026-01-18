@echo off
setlocal enabledelayedexpansion

:: ===========================================
:: KONFIGURATION
:: ===========================================
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ===========================================

echo ===========================================
echo       Projekt-Installer
echo ===========================================
echo URL:    %REPO_URL%
echo Branch: %BRANCH%
echo Start:  %START_FILE%
echo ===========================================
echo.

:CHOOSE_FOLDER
echo [+] Bitte waehle den Installations-Ordner im Fenster aus...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Ordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo [!] Kein Ordner gewaehlt. Abbruch.
    pause
    exit /b
)

echo [+] Zielordner: "%TARGET_DIR%"
echo.

:CHECK_GIT
echo [+] Pruefe auf Git...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Git fehlt. Installation via Winget...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    if %errorlevel% neq 0 (
        echo [!] Fehler bei der Installation.
        pause
        exit /b
    )
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    echo [+] Git installiert.
) else (
    echo [+] Git ist vorhanden.
)

:CLONE_REPO
echo [+] Klone Branch %BRANCH%...
cd /d "%TARGET_DIR%"
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo [!] Fehler beim Klonen.
    pause
    exit /b
)

:START_LOGIC
echo [+] Suche %START_FILE%...
if exist "%START_FILE%" (
    echo [+] Starte Datei...
    call "%START_FILE%"
) else (
    echo [!] %START_FILE% nicht gefunden.
    echo [+] Gehe einen Ordner zurueck.
    cd ..
    echo.
    echo Beendet. Druecke eine Taste.
    pause >nul
    exit
)

pause
