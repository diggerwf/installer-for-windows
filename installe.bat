@echo off
setlocal enabledelayedexpansion

:: ===========================================
:: KONFIGURATION
:: ===========================================
:: Hier deine Daten anpassen:
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ===========================================

echo ===========================================
echo       Projekt-Installer (Clean Version)
echo ===========================================
echo URL:    %REPO_URL%
echo Branch: %BRANCH%
echo Start:  %START_FILE%
echo ===========================================
echo.

:CHOOSE_FOLDER
echo [+] Bitte waehle jetzt den Installations-Ordner...
:: PowerShell Dialog ohne Sonderzeichen
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Ordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo [!] Abbruch: Kein Ordner ausgewaehlt.
    pause
    exit /b
)

echo [+] Zielordner: "%TARGET_DIR%"
echo.

:CHECK_GIT
echo [+] Pruefe ob Git installiert ist...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Git fehlt. Installation via Winget startet...
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
    echo [+] Git ist bereits vorhanden.
)

:CLONE_REPO
echo.
echo [+] Klone Branch %BRANCH%...
cd /d "%TARGET_DIR%"

:: Klont den spezifischen Branch
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] FEHLER beim Klonen. Ist der Ordner evtl. nicht leer?
    pause
    exit /b
)

:START_LOGIC
echo.
echo [+] Suche nach der Datei: %START_FILE%
if exist "%START_FILE%" (
    echo [+] Datei gefunden! Starte Projekt jetzt...
    echo.
    call "%START_FILE%"
) else (
    echo [!] %START_FILE% wurde nicht gefunden.
    echo [+] Gehe einen Ordner zurueck...
    cd ..
    echo.
    echo ===========================================
    echo Vorgang beendet. Beliebige Taste druecken zum Beenden.
    pause >nul
    exit
)

pause
