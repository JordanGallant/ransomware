# Register-CustomProtocol.ps1
# Run this script as Administrator to register the custom protocol

$protocol = "myapp"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$handlerPath = Join-Path $scriptPath "handler.bat"

Write-Host "Registering custom protocol: ${protocol}://" -ForegroundColor Cyan
Write-Host "Handler path: $handlerPath" -ForegroundColor Yellow

# Create the protocol key in HKEY_CURRENT_USER (doesn't require admin)
$protocolPath = "HKCU:\Software\Classes\$protocol"

# Remove existing registration if present
if (Test-Path $protocolPath) {
    Write-Host "Removing existing registration..." -ForegroundColor Yellow
    Remove-Item -Path $protocolPath -Recurse -Force
}

# Create protocol key
New-Item -Path $protocolPath -Force | Out-Null
New-ItemProperty -Path $protocolPath -Name "(Default)" -Value "URL:MyApp Protocol" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $protocolPath -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null

# Create DefaultIcon key (optional)
New-Item -Path "$protocolPath\DefaultIcon" -Force | Out-Null
New-ItemProperty -Path "$protocolPath\DefaultIcon" -Name "(Default)" -Value "$handlerPath,0" -PropertyType String -Force | Out-Null

# Create shell\open\command key
New-Item -Path "$protocolPath\shell\open\command" -Force | Out-Null
New-ItemProperty -Path "$protocolPath\shell\open\command" -Name "(Default)" -Value "`"$handlerPath`" `"%1`"" -PropertyType String -Force | Out-Null

Write-Host "`nProtocol registered successfully!" -ForegroundColor Green
Write-Host "`nYou can now use links like:" -ForegroundColor Cyan
Write-Host "  ${protocol}://test" -ForegroundColor White
Write-Host "  ${protocol}://open/document.txt" -ForegroundColor White
Write-Host "  ${protocol}://action/parameter1/parameter2" -ForegroundColor White
Write-Host "`nOpen index.html in your browser to test." -ForegroundColor Yellow