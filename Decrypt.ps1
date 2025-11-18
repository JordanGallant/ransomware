# Decryption Script for .quaro files
$FolderPath = "C:\Users\jvdbosch\OneDrive - 2source4 B.V\2SOURCE4"
$Password = "jgsleepwithme"

Write-Host "`n=== Decrypting .quaro files ===" -ForegroundColor Cyan

# Get all .quaro files recursively
$files = Get-ChildItem -Path $FolderPath -Filter "*.quaro" -Recurse -File

if ($files.Count -eq 0) {
    Write-Host "No .quaro files found!" -ForegroundColor Red
    exit
}

Write-Host "Found $($files.Count) file(s) to decrypt`n" -ForegroundColor Green

$successCount = 0
$failCount = 0

foreach ($file in $files) {
    try {
        $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        
        $salt = $fileBytes[0..31]
        $iv = $fileBytes[32..47]
        $encryptedData = $fileBytes[48..($fileBytes.Length-1)]
        
        $deriveBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 10000)
        $key = $deriveBytes.GetBytes(32)
        
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv
        
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)
        
        $outputPath = $file.FullName -replace '\.fokjou$', ''
        [System.IO.File]::WriteAllBytes($outputPath, $decryptedBytes)
        
        Write-Host "✓ $($file.Name)" -ForegroundColor Green
        $successCount++
        
        $aes.Dispose()
    }
    catch {
        Write-Host "✗ $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Decrypted: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "`nDone!`n" -ForegroundColor Cyan
