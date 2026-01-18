@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer
echo ===========================================
echo URL:    %REPO_URL%
echo Branch: %BRANCH%
echo Start:  %START_FILE%
echo.

:CHOOSE_FOLDER
echo [+] Suche Ordner... Bitte im Fenster waehlen.
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Ordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo [!] Abbruch: Kein Ordner gewaehlt.
    pause
    exit /b
)

echo [+] Zielordner: %TARGET_DIR%
echo.

:CHECK_GIT
echo [+] Pruefe Git...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Git fehlt. Installation via winget...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    if %errorlevel% neq 0 (
        echo [!] Fehler bei Git-Installation.
        pause
        exit /b
    )
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
) else (
    echo [+] Git ist bereit.
)

:CLONE_REPO
echo [+] Klone Projekt...
cd /d "%TARGET_DIR%"
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo [!] Fehler beim Klonen. Ordner nicht leer?
    pause
    exit /b
)

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [!] %START_FILE% nicht gefunden.
    cd ..
    echo [+] Beendet.
    pause
    exit
)
