@echo off
:: Aktiviert die verzögerte Variablenerweiterung für bessere Stabilität
setlocal enabledelayedexpansion

:: ===========================================
:: ⚙️ KONFIGURATION
:: ===========================================
:: Hier kannst du deine Standard-Werte anpassen:
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ===========================================

echo ===========================================
echo       Automatischer Projekt-Installer
echo ===========================================
echo URL:    %REPO_URL%
echo Branch: %BRANCH%
echo Start:  %START_FILE%
echo ===========================================
echo.

:CHOOSE_FOLDER
echo [+] Suche Installationsordner...
echo (Bitte waehle einen Ordner im Auswahlfenster aus)
echo.

:: PowerShell-Trick, um den Windows-Ordnerdialog zu oeffnen
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Waehle den Zielordner'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

:: Prüfung, ob ein Ordner gewählt wurde
if "%TARGET_DIR%"=="" (
    echo [!] Abbruch: Kein Ordner ausgewaehlt.
    pause
    exit /b
)

echo [+] Zielordner: "%TARGET_DIR%"
echo.

:CHECK_GIT
echo [+] Pruefe Git-Status...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Git nicht gefunden. Automatische Installation via Winget startet...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    
    if %errorlevel% neq 0 (
        echo [!] FEHLER: Git konnte nicht installiert werden.
        pause
        exit /b
    )
    :: Pfad fuer diese Sitzung aktualisieren
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    echo [+] Git erfolgreich installiert.
) else (
    echo [+] Git ist bereits installiert.
)

:CLONE_REPO
echo.
echo [+] Klone Repository (Branch: %BRANCH%)...
:: Wechselt das Laufwerk und den Ordner
cd /d "%TARGET_DIR%"

:: Klont den spezifischen Branch in das aktuelle Verzeichnis (.)
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] FEHLER beim Klonen. 
    echo Stellen Sie sicher, dass der Ordner leer ist und der Link stimmt.
    pause
    exit /b
)

:START_LOGIC
echo.
echo [+] Pruefe auf Start-Datei: %START_FILE%
if exist "%START_FILE%" (
    echo [+] %START_FILE% gefunden! Starte Projekt...
    echo.
    call "%START_FILE%"
) else (
    echo [!] %START_FILE% nicht gefunden.
    echo [+] Gehe zurueck in den Ursprungsordner...
    cd ..
    echo.
    echo ===========================================
    echo Vorgang beendet. Druecke eine Taste zum Schliessen.
    pause >nul
    exit
)

pause
