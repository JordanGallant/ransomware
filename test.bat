@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "'Hello from BAT!' | Out-File $env:USERPROFILE\Desktop\bat_test.txt"
pause