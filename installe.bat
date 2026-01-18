@echo off
setlocal enabledelayedexpansion

:: --- EINSTELLUNGEN ---
:: Das Repo MUSS oeffentlich sein, damit kein Login abgefragt wird!
set "REPO_URL=https://github.com/diggerwf/installer-for-windows.git"
set "BRANCH=beta-1"
set "START_FILE=start.bat"
:: ---------------------

echo PRUEFE SYSTEM...

:CHOOSE_FOLDER
echo Bitte Ordner im Fenster waehlen...
set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Installationsordner waehlen'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "%psCmd%"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo Abbruch: Kein Ordner gewaehlt.
    pause
    exit /b
)

:CHECK_GIT
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Git wird installiert...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

:CLONE_REPO
echo Klone Projekt...
cd /d "%TARGET_DIR%"
:: Der Befehl klont ohne Account-Abfrage (nur bei Public Repos)
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% neq 0 (
    echo Fehler beim Download. Ist das Repo oeffentlich?
    pause
    exit /b
)

:START_LOGIC
if exist "%START_FILE%" (
    echo Starte %START_FILE%...
    call "%START_FILE%"
) else (
    echo %START_FILE% nicht gefunden. Zurueck...
    cd ..
    pause
)
