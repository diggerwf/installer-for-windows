@echo off
setlocal
chcp 65001 >nul

:: ===========================================
:: ⚙️ KONFIGURATION
:: ===========================================
:: Hier kannst du deine Projektdaten anpassen:
set "REPO_URL=https://github.com/USER/PROJEKT.git"
set "BRANCH=main"
set "START_FILE=start.bat"
:: ===========================================

echo 🌟 ===========================================
echo 🚀       Automatischer Projekt-Installer
echo 🌟 ===========================================
echo 📂 Ziel-Branch: %BRANCH%
echo 📥 Start-Datei: %START_FILE%
echo.

:CHOOSE_FOLDER
echo 🔍 Öffne Fenster zur Ordnerauswahl... 📁
:: PowerShell Dialog für die Ordnerwahl (inkl. "Neuen Ordner erstellen")
for /f "delims=" %%I in ('powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Wähle den Installationsordner'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"') do set "TARGET_DIR=%%I"

if "%TARGET_DIR%"=="" (
    echo ❌ Keine Auswahl getroffen. Installation abgebrochen. 🛑
    pause
    exit /b
)

echo ✅ Ausgewählter Ordner: "%TARGET_DIR%"
echo.

:CHECK_GIT
echo 🛠️ Prüfe ob Git installiert ist...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Git wurde nicht gefunden. Installation via winget startet... 🛠️
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    
    if %errorlevel% neq 0 (
        echo ❌ Fehler bei der Git-Installation. Bitte manuell installieren! 🛑
        pause
        exit /b
    )
    :: Pfad für die aktuelle Session aktualisieren
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    echo ✅ Git wurde erfolgreich installiert! 🎉
) else (
    echo ✅ Git ist bereits vorhanden. 😎
)

:CLONE_REPO
echo.
echo 📥 Klone Branch "%BRANCH%" von %REPO_URL%...
:: Wechselt in das Zielverzeichnis (/d für Laufwerkswechsel)
cd /d "%TARGET_DIR%"

:: Klont den spezifischen Branch in den aktuellen Ordner
git clone -b %BRANCH% %REPO_URL% .

if %errorlevel% equ 0 (
    echo.
    echo ✨ ===========================================
    echo ✅ STATUS: Download erfolgreich! 🎊
    echo ✨ ===========================================
) else (
    echo.
    echo ❌ Fehler beim Klonen. Ist der Ordner eventuell nicht leer? 🧐
    pause
    exit /b
)

:START_LOGIC
echo 🔍 Prüfe ob "%START_FILE%" vorhanden ist...
if exist "%START_FILE%" (
    echo 🚀 "%START_FILE%" gefunden! Starte Projekt... ⚡
    call "%START_FILE%"
) else (
    echo ⚠️ "%START_FILE%" wurde im Ordner nicht gefunden. 🧐
    echo 🔙 Gehe zurück zum vorherigen Ordner...
    cd ..
    echo.
    echo ✅ Vorgang beendet.
    echo ⌨️ Drücke eine beliebige Taste zum Beenden...
    pause >nul
    exit
)

pause
