@echo off
setlocal enabledelayedexpansion

:: --- EINSTELLUNGEN ---
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer
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
    echo [+] Git wird installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:CLONE_REPO
echo [+] Wechsle in Zielordner...
cd /d "%TARGET_DIR%"

:: PRUEFUNG: Ist der Ordner leer?
dir /a /b | findstr . >nul 2>&1
if %errorlevel% equ 0 (
    echo [!] Ordner ist nicht leer. Erstelle Unterordner...
    :: Extrahiert den Namen aus der URL (alles nach dem letzten / und ohne .git)
    for %%F in ("%REPO_URL%") do set "FOLDER_NAME=%%~nF"
    mkdir "!FOLDER_NAME!" 2>nul
    cd "!FOLDER_NAME!"
    echo [+] Neuer Zielpfad: !CD!
)

echo [+] Klone Projekt (ohne Login)...
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo [!] Fehler beim Download.
    pause
    exit /b
)

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [-] %START_FILE% nicht gefunden. Fertig.
    pause
)
