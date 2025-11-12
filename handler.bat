@echo off
REM handler.bat - Custom protocol handler
REM This batch file is called when myapp:// links are clicked

echo ========================================
echo Custom Protocol Handler
echo ========================================
echo.
echo Full URL received: %1
echo.

REM Remove the protocol prefix (myapp://)
set "URL=%~1"
set "URL=%URL:myapp://=%"

echo Parsed parameters: %URL%
echo.
echo ========================================
echo.

REM Parse the URL and perform actions
REM Example: myapp://open/file.txt would have URL=open/file.txt

REM You can add your logic here
if "%URL%"=="test" (
    echo TEST ACTION EXECUTED
    notepad.exe
) else if "%URL:~0,4%"=="open" (
    echo OPEN ACTION DETECTED
    echo Parameter: %URL:~5%
    REM Open a file or application
    explorer.exe
) else (
    echo GENERIC ACTION
    echo Received: %URL%
    msg * "MyApp Protocol Handler: %URL%"
)

echo.
echo Press any key to close...
pause >nul