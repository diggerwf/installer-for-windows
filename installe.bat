@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
:: Nutze die normale HTTPS URL
set "REPO_URL=https://github.com/diggerwf/installer-for-windows.git"
set "BRANCH=beta-1"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer
echo ===========================================
echo URL: %REPO_URL%
echo.

:CHOOSE_FOLDER
echo [+] Bitte Ordner im Fenster waehlen...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Zielordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo [!] Abbruch: Kein Ordner gewaehlt.
    pause
    exit /b
)

:: Wechsel in den Ordner
cd /d "%TARGET_DIR%"

:CHECK_GIT
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [+] Git wird installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:CLONE_REPO
:: PRÜFUNG: Ist der Ordner wirklich leer? 
:: (Wenn nicht, erstellen wir einen Unterordner basierend auf dem Projektnamen)
dir /a /b | findstr . >nul 2>&1
if %errorlevel% equ 0 (
    echo [!] Ordner nicht leer. Erstelle Unterordner...
    for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
    mkdir "!DIR_NAME!" 2>nul
    cd "!DIR_NAME!"
)

echo [+] Klone Projekt anonym...
:: -c credential.helper= verhindert Login-Abfragen bei Public Repos
:: --depth 1 sorgt fuer schnellen Download ohne Upload-Historie
git -c credential.helper= clone --depth 1 -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] FEHLER: Download nicht moeglich. 
    echo Grund: Repo ist privat oder die URL ist falsch.
    pause
    exit /b
)

:: Deaktiviere Upload-Moeglichkeit (Push) zur Sicherheit
git remote set-url --push origin no_push

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [+] Fertig. %START_FILE% nicht im Projekt gefunden.
    pause
)
