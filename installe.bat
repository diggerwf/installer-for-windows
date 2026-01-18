@echo off
setlocal

:: --- KONFIGURATION ---
:: Hier die GitHub-URL und den gewünschten Branch anpassen
set "REPO_URL=https://github.com/diggerwf/installer-for-windows.git"
set "BRANCH=beta-1"
:: ---------------------

echo ===========================================
echo       Automatischer Projekt-Installer
echo ===========================================
echo Ziel-Branch: %BRANCH%
echo.

:CHOOSE_FOLDER
echo Oeffne Fenster zur Ordnerauswahl...
:: PowerShell Dialog für Ordnerwahl
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Waehle den Installationsordner'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo Keine Auswahl getroffen. Installation abgebrochen.
    pause
    exit /b
)

echo Ausgewaehlter Ordner: "%TARGET_DIR%"
echo.

:CHECK_GIT
echo Pruefe ob Git installiert ist...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Git wurde nicht gefunden. Installation via winget...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    
    if %errorlevel% neq 0 (
        echo Fehler bei der Git-Installation.
        pause
        exit /b
    )
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    echo Git wurde erfolgreich installiert.
) else (
    echo Git ist bereits vorhanden.
)

:CLONE_REPO
echo.
echo Klone Branch "%BRANCH%" von %REPO_URL%...
cd /d "%TARGET_DIR%"

:: Klont gezielt den definierten Branch
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% equ 0 (
    echo.
    echo ===========================================
    echo STATUS: Installation von "%BRANCH%" erfolgreich!
    echo ===========================================
) else (
    echo.
    echo Fehler beim Klonen. 
    echo Pruefe ob der Branch-Name korrekt ist und der Ordner leer ist.
)

pause
