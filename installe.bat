@echo off
setlocal enabledelayedexpansion

:: --- KONFIGURATION ---
:: Nutze die normale HTTPS URL (muss ein oeffentliches Repo sein!)
set "REPO_URL=https://github.com/diggerwf/installer-for-windows.git"
set "BRANCH=beta-1"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer (Nur Download)
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

:CHECK_GIT
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [+] Git wird installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:CLONE_REPO
echo [+] Wechsle in: "%TARGET_DIR%"
cd /d "%TARGET_DIR%"

:: Falls Ordner nicht leer ist, Unterordner erstellen
dir /a /b | findstr . >nul 2>&1
if %errorlevel% equ 0 (
    for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
    echo [!] Ordner nicht leer. Nutze Unterordner: !DIR_NAME!
    mkdir "!DIR_NAME!" 2>nul
    cd "!DIR_NAME!"
)

echo [+] Klone Projekt anonym (Nur Download)...
:: Erklaerung der Parameter:
:: -c credential.helper= : Ignoriert gespeicherte Logins
:: --depth 1 : Laedt nur die neueste Version (keine ganze Historie = schneller)
git -c credential.helper= clone --depth 1 -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] FEHLER: Download fehlgeschlagen. 
    echo Grund: Das Repo ist privat oder die URL ist falsch.
    pause
    exit /b
)

:: Deaktiviere Upload-Moeglichkeit (Push) fuer diesen Ordner zur Sicherheit
git remote set-url --push origin no_push

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [+] Fertig. %START_FILE% nicht gefunden.
    pause
)
