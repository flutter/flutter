@echo off
REM Personal Training App Launcher
REM This script keeps the Flutter dev server running and opens the app

setlocal enabledelayedexpansion

REM Check if Flutter dev server is already running
tasklist /FI "IMAGENAME eq dart.exe" 2>NUL | find /I /N "dart.exe">NUL
if "%ERRORLEVEL%"=="0" (
  echo Dev server is running. Opening app...
  goto OPEN_BROWSER
)

REM Start the dev server in a new window
echo Starting Flutter development server...
start "Flutter Dev Server" /B cmd /c "cd /d c:\Users\steme\Documents\AP\flutter\examples\personal_training_app && flutter run -d chrome"

REM Wait for server to start
timeout /t 8 /nobreak

:OPEN_BROWSER
REM Try to find Chrome
for %%A in (
  "C:\Program Files\Google\Chrome\Application\chrome.exe"
  "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
  "%LocalAppData%\Google\Chrome\Application\chrome.exe"
) do (
  if exist %%A (
    start %%A "http://127.0.0.1:9090"
    exit /b 0
  )
)

REM Fallback: open with default browser
start http://127.0.0.1:9090
