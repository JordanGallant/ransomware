Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -Command ""'VBS executed' | Out-File $env:USERPROFILE\Desktop\vbs_test.txt""", 0, False