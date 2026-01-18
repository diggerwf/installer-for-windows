@echo off
setlocal enabledelayedexpansion

:: --- EINSTELLUNGEN ---
:: Achte darauf, dass hinter .git kein Leerzeichen ist!
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ---------------------

echo ===========================================
echo       Projekt-Installer
echo ===========================================

:CHOOSE_FOLDER
echo [+] Bitte Ordner im Fenster waehlen...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Ordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
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

:: Falls Ordner nicht leer, erstelle Unterordner
dir /a /b | findstr . >nul 2>&1
if %errorlevel% equ 0 (
    for %%F in ("%REPO_URL%") do set "DIR_NAME=%%~nF"
    mkdir "!DIR_NAME!" 2>nul
    cd "!DIR_NAME!"
)

echo [+] Downloade Projekt...
:: Dieser Befehl schaltet den Login-Helfer nur fuer diesen einen Befehl AUS
git -c credential.helper= clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo.
    echo [!] Download fehlgeschlagen.
    echo Wenn ein Login verlangt wird, ist die URL falsch oder das Repo nicht public.
    pause
    exit /b
)

:START_LOGIC
if exist "%START_FILE%" (
    echo [+] Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo [+] Fertig.
    pause
)
