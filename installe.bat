@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
set "REPO_URL=https://github.com/diggerwf/installer-for-windows.git"
set "BRANCH=beta-1"
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
    [cite_start]winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements [cite: 2]
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:PROCESS
set "DIR_NAME="

if exist ".git" (
    [cite_start]echo [+] Bestehendes Projekt gefunden. [cite: 3]
    [cite_start]echo Pruefe auf Updates... [cite: 3]
    git remote set-url origin "!REPO_URL!"
    [cite_start]git -c credential.helper= fetch origin %BRANCH% --quiet [cite: 4]
    
    for /f "tokens=*" %%a in ('git rev-parse HEAD') do set "LOCAL_HASH=%%a"
    for /f "tokens=1" %%a in ('git ls-remote origin %BRANCH%') do set "REMOTE_HASH=%%a"
    
    if "!LOCAL_HASH!"=="!REMOTE_HASH!" (
        [cite_start]echo [+] Alles aktuell. [cite: 5]
    ) else (
        echo [+] Update verfuegbar. Lade neue Daten...
        git pull origin %BRANCH%
    )
) else (
    echo [+] Kein Projekt gefunden. Starte Neu-Installation...
    
    set "IS_EMPTY=YES"
    dir /b /a | findstr . >nul 2>&1
    if %errorlevel% equ 0 set "IS_EMPTY=NO"

    if "!IS_EMPTY!"=="YES" (
        echo [+] Ordner ist leer. Klone Branch %BRANCH%...
        git -c credential.helper= clone -b %BRANCH% %REPO_URL% .
    ) else (
        [cite_start]for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF" [cite: 6]
        echo [!] Ordner nicht leer. Klone in Unterordner: !DIR_NAME!
        
        git -c credential.helper= clone -b %BRANCH% %REPO_URL% "!DIR_NAME!"
        
        if exist "!DIR_NAME!" (
            cd "!DIR_NAME!"
        )
    )
)

:START_LOGIC
echo.
echo --- Startvorgang ---

:: 1. Prüfung im aktuellen Verzeichnis
if exist "%START_FILE%" (
    echo [+] %START_FILE% gefunden. Starte...
    echo -------------------------------------------
    call "%START_FILE%"
    goto :END
)

:: 2. Prüfung im Unterordner (falls vorhanden)
if defined DIR_NAME (
    if exist "!DIR_NAME!\%START_FILE%" (
        echo [+] Datei im Unterordner "!DIR_NAME!" gefunden.
        cd "!DIR_NAME!"
        echo -------------------------------------------
        call "%START_FILE%"
        goto :END
    )
)

:: 3. Fehlerfall: Datei ist nicht da
echo.
echo [!] FEHLER: Die Datei "%START_FILE%" konnte nicht gefunden werden.
echo [i] Inhalt des aktuellen Ordners:
dir /b /a-d
echo.
echo Druecke eine belibige Taste um zu beenden
pause
exit

:END
exit
