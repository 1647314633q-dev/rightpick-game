@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ============================================================
rem  RightPick Arcade - Exhibition Kiosk launcher (Windows)
rem  Starts a local web server, then opens Chrome in kiosk mode.
rem  Keyboard: Alt+F4 to exit, P for the staff panel.
rem ============================================================

set "PORT=8080"
set "URL=http://localhost:%PORT%/?kiosk=1"
set "PROFILE=%~dp0.kiosk-profile"

echo ============================================
echo   RightPick Arcade - Exhibition Kiosk
echo ============================================
echo.

rem ---------- 1. pick a local server ----------
set "PY="
where py >nul 2>nul
if not errorlevel 1 set "PY=py"
if not defined PY (
  where python >nul 2>nul
  if not errorlevel 1 set "PY=python"
)

if defined PY (
  echo [1/3] Starting local server with Python...
  start "RightPick Server" /min "%PY%" "%~dp0server.py" %PORT%
) else (
  echo [1/3] Python not found - using the PowerShell fallback server...
  start "RightPick Server" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0server.ps1"
)

rem ---------- 2. wait until the server answers ----------
echo [2/3] Waiting for the server...
set "READY="
for /l %%i in (1,1,30) do (
  if not defined READY (
    powershell -NoProfile -Command "try{$c=New-Object Net.Sockets.TcpClient;$c.Connect('127.0.0.1',%PORT%);$c.Close();exit 0}catch{exit 1}" >nul 2>nul
    if not errorlevel 1 (
      set "READY=1"
    ) else (
      ping -n 2 127.0.0.1 >nul
    )
  )
)

if not defined READY (
  echo.
  echo [X] The server did not start. Port %PORT% may be in use.
  echo     Close other programs and try again.
  pause
  exit /b 1
)

rem ---------- 3. find Chrome / Edge ----------
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "CHROME=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not defined CHROME if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "CHROME=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"

if not defined CHROME (
  echo.
  echo [X] Chrome or Edge was not found. Please install Google Chrome.
  echo     Or open this URL manually: %URL%
  pause
  exit /b 1
)

echo [3/3] Opening the game in kiosk mode...
start "" "%CHROME%" --kiosk "%URL%" ^
 --user-data-dir="%PROFILE%" ^
 --no-first-run --no-default-browser-check ^
 --disable-infobars --disable-session-crashed-bubble ^
 --disable-pinch --overscroll-history-navigation=0 ^
 --autoplay-policy=no-user-gesture-required ^
 --use-fake-ui-for-media-stream

echo.
echo ============================================
echo   Running.
echo   Exit kiosk:        Alt + F4
echo   Staff panel:       P
echo   Switch game:       1 2 3 4
echo   Back to menu:      Esc
echo ============================================
timeout /t 4 >nul
endlocal
