@echo off
:: DotMaster Check Command
::
:: Simple wrapper to run the PowerShell validation script
:: Usage: dmcheck

echo.
echo ========================================================
echo               DOTMASTER CHECK COMMAND
echo ========================================================
echo.

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -NoProfile -Command "& { . '%~dp0Scripts\dmcheck.ps1'; exit $LASTEXITCODE }"

echo.
if %ERRORLEVEL% EQU 0 (
  echo Check completed successfully!
) else (
  echo Check completed with warnings or errors.
)
echo. 