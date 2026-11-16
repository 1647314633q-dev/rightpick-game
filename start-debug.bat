@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem ============================================================
rem  RightPick Arcade - setup / testing launcher
rem  Opens a normal Chrome window (no forced fullscreen, no
rem  auto-approved camera). Use this to set up the webcam angle
rem  or to try the game on a laptop.
rem ============================================================

set "PORT=8080"
set "URL=http://localhost:%PORT%/"

set "PY="
where py >nul 2>nul
if not errorlevel 1 set "PY=py"
if not defined PY (
  where python >nul 2>nul
  if not errorlevel 1 set "PY=python"
)

if defined PY (
  start "RightPick Server" /min "%PY%" "%~dp0server.py" %PORT%
) else (
  start "RightPick Server" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0server.ps1"
)

ping -n 3 127.0.0.1 >nul

set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if defined CHROME (
  start "" "%CHROME%" "%URL%"
) else (
  start "" "%URL%"
)
