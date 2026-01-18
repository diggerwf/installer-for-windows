@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer & Updater
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

cd /d "%TARGET_DIR%"

:CHECK_GIT
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [+] Git wird installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:PROCESS
:: Prüfen, ob bereits ein Git-Projekt hier liegt
if exist ".git" (
    echo [+] Bestehendes Projekt gefunden. Pruefe auf Updates...
    git remote set-url origin "!REPO_URL!"
    
    :: Fetch ohne Prompt
    git -c credential.helper= fetch origin %BRANCH% --quiet
    
    for /f "tokens=*" %%a in ('git rev-parse HEAD') do set "LOCAL_HASH=%%a"
    for /f "tokens=1" %%a in ('git ls-remote origin %BRANCH%') do set "REMOTE_HASH=%%a"
    
    if "!LOCAL_HASH!"=="!REMOTE_HASH!" (
        echo [+] Alles aktuell.
    ) else (
        echo [+] Update verfuegbar. Lade neue Daten...
        git pull origin %BRANCH%
    )
) else (
    echo [+] Kein Projekt gefunden. Starte Neu-Installation...
    
    :: Falls Ordner nicht leer, Unterordner erstellen
    dir /a /b | findstr . >nul 2>&1
    if %errorlevel% equ 0 (
        for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
        mkdir "!DIR_NAME!" 2>nul
        cd "!DIR_NAME!"
    )
    
    echo [+] Klone Branch %BRANCH%...
    git -c credential.helper= clone -b %BRANCH% %REPO_URL% .
)

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [+] Fertig. %START_FILE% nicht gefunden.
    pause
)
