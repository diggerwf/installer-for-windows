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
echo [1/4] Ordner-Auswahl...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Zielordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo [!] Abbruch: Kein Ordner gewaehlt. [cite: 1]
    pause
    exit /b
)

echo [+] Gewaehlter Pfad: "%TARGET_DIR%"
cd /d "%TARGET_DIR%"

:CHECK_GIT
echo [2/4] Pruefe Systemvoraussetzungen (Git)...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Git fehlt. Starte Installation via Winget... [cite: 2]
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements [cite: 2]
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
) else (
    for /f "tokens=*" %%v in ('git --version') do echo [+] Gefunden: %%v
)

:PROCESS
echo [3/4] Analysiere Projekt-Status...

if exist ".git" (
    echo [i] Info: Bestehendes Git-Repository erkannt. [cite: 3]
    echo [+] Synchronisiere mit: %REPO_URL% [cite: 3]
    git remote set-url origin "!REPO_URL!" [cite: 3]
    
    echo [+] Suche nach Updates auf Server... 
    git -c credential.helper= fetch origin %BRANCH% --progress
    
    for /f "tokens=*" %%a in ('git rev-parse HEAD') do set "LOCAL_HASH=%%a" 
    for /f "tokens=1" %%a in ('git ls-remote origin %BRANCH%') do set "REMOTE_HASH=%%a" 
    
    echo [i] Lokal:  !LOCAL_HASH:~0,7!
    echo [i] Server: !REMOTE_HASH:~0,7!
    
    if "!LOCAL_HASH!"=="!REMOTE_HASH!" (
        echo [+] Status: Alles aktuell. Keine Aktion erforderlich. [cite: 5]
    ) else (
        echo [!] Status: Update verfuegbar! Lade Daten... [cite: 5]
        git pull origin %BRANCH% --progress [cite: 5]
    )
) else (
    echo [i] Info: Kein Projekt gefunden. Initialisiere Download... [cite: 6]
    
    dir /a /b | findstr . >nul 2>&1
    if %errorlevel% equ 0 (
        for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
        echo [!] Warnung: Ordner nicht leer. Erstelle Unterordner: "!DIR_NAME!" [cite: 6]
        
        echo [+] Starte Download (Klonen)...
        git -c credential.helper= clone -b %BRANCH% --progress %REPO_URL% "!DIR_NAME!"
        
        if exist "!DIR_NAME!" (
            echo [+] Wechsel in Projektverzeichnis...
            cd /d "!DIR_NAME!"
        )
    ) else (
        echo [+] Ordner ist leer. Klone direkt in dieses Verzeichnis... [cite: 6]
        git -c credential.helper= clone -b %BRANCH% --progress %REPO_URL% . [cite: 6]
    )
)

:START_LOGIC
echo [4/4] Abschlussprüfung...
echo [i] Aktueller Standort: %CD%

if exist "%START_FILE%" (
    echo [+] %START_FILE% wurde gefunden.
    echo [+] Starte Anwendung...
    echo -------------------------------------------
    call "%START_FILE%" [cite: 1]
    exit
) else (
    echo.
    echo [!] KRITISCHER FEHLER: "%START_FILE%" fehlt! [cite: 1]
    echo [i] Pruefe Inhalt von %CD%:
    dir /b /a-d
    echo.
    echo Druecke eine belibige Taste um zu beenden
    pause
    exit
)
