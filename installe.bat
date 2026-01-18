@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer ^& Updater
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
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements [cite: 2]
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:PROCESS
:: Falls bereits eine .git Datei da ist, nur updaten [cite: 3]
if exist ".git" (
    echo [+] Bestehendes Projekt gefunden. Pruefe auf Updates... [cite: 3]
    git remote set-url origin "!REPO_URL!"
    git -c credential.helper= fetch origin %BRANCH% --quiet [cite: 4]
    
    for /f "tokens=*" %%a in ('git rev-parse HEAD') do set "LOCAL_HASH=%%a"
    for /f "tokens=1" %%a in ('git ls-remote origin %BRANCH%') do set "REMOTE_HASH=%%a"
    
    if "!LOCAL_HASH!"=="!REMOTE_HASH!" (
        echo [+] Alles aktuell. [cite: 5]
    ) else (
        echo [+] Update verfuegbar. Lade neue Daten... [cite: 5]
        git pull origin %BRANCH% [cite: 5]
    )
) else (
    :: Prüfung ob Ordner leer ist
    dir /a /b | findstr . >nul 2>&1
    if %errorlevel% equ 0 (
        :: Ordner NICHT leer -> Unterordner erstellen und reingehen
        for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF" 
        echo [+] Ordner nicht leer. Erstelle Unterordner: !DIR_NAME!
        
        :: Klone direkt in den Unterordner
        git -c credential.helper= clone -b %BRANCH% %REPO_URL% "!DIR_NAME!"
        if exist "!DIR_NAME!" cd /d "!DIR_NAME!"
    ) else (
        :: Ordner IST leer -> direkt hierher klonen
        echo [+] Klone Branch %BRANCH%...
        git -c credential.helper= clone -b %BRANCH% %REPO_URL% .
    )
)

:START_LOGIC
echo.
echo --- Pruefe Start-Datei ---
if exist "%START_FILE%" (
    echo [+] %START_FILE% gefunden. Starte jetzt...
    echo -------------------------------------------
    call "%START_FILE%"
    exit
) else (
    echo.
    echo [!] FEHLER: Die Datei "%START_FILE%" konnte nicht gefunden werden.
    echo [i] Aktueller Pfad: %CD%
    echo [i] Inhalt dieses Ordners:
    dir /b
    echo.
    echo Druecke eine belibige Taste um zu beenden
    pause
    exit
)
