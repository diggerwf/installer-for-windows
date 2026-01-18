@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
:: Nutze die HTTPS-URL. Bei oeffentlichen Repos ist kein Login noetig.
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer (No Login)
echo ===========================================

:CHOOSE_FOLDER
echo [+] Bitte Ordner im Fenster waehlen...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Installationsordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
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
echo [+] Wechsle in Zielordner: "%TARGET_DIR%"
cd /d "%TARGET_DIR%"

:: Versuch 1: Direkt in den gewaehlten Ordner klonen
echo [+] Klone Projekt...
git clone -b %BRANCH% %REPO_URL% . 2>git_error.log

:: Wenn Fehler (z.B. Ordner nicht leer), Versuch 2: In Unterordner klonen
if %errorlevel% neq 0 (
    echo [!] Ordner nicht leer oder Fehler. Erstelle Unterordner...
    :: Extrahiert Namen aus der URL
    for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
    mkdir "!DIR_NAME!" 2>nul
    cd "!DIR_NAME!"
    git clone -b %BRANCH% %REPO_URL% .
)
del git_error.log >nul 2>&1

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [-] %START_FILE% nicht gefunden.
    echo [+] Aktueller Pfad: !CD!
    echo [+] Fertig.
    pause
)
