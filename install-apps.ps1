# Windows 11 Apps Installer Script
# Save this file as "install-apps.ps1"

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Exit 1
}

# Function to check if winget is installed
function Test-WinGet {
    try {
        # Check if winget is available
        winget -v | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check if winget is installed
if (-not (Test-WinGet)) {
    Write-Host "Winget is not installed. Please install App Installer from the Microsoft Store."
    Write-Host "Opening Microsoft Store to the App Installer page..."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Exit 1
}

# Create a log file
$logFile = "$env:USERPROFILE\Desktop\windows_setup_log.txt"
"Windows Setup Log - $(Get-Date)" | Out-File -FilePath $logFile

# SECTION 1: REMOVE BLOATWARE
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "REMOVING WINDOWS BLOATWARE" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# List of bloatware apps to remove
$bloatwareApps = @(
    # Entertainment Apps
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.XboxApp"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    
    # Games
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MixedReality.Portal"
    
    # Unnecessary Microsoft Apps
    "Microsoft.BingWeather"
    "Microsoft.BingNews"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Paint3D"
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.YourPhone"
    "Microsoft.MicrosoftStickyNotes"
)

# Remove bloatware
$totalBloatware = $bloatwareApps.Count
$currentApp = 0

foreach ($app in $bloatwareApps) {
    $currentApp++
    $progressPercentage = ($currentApp / $totalBloatware) * 100
    
    Write-Progress -Activity "Removing Bloatware" -Status "$app ($currentApp of $totalBloatware)" -PercentComplete $progressPercentage
    
    try {
        Write-Host "Attempting to remove $app..." -ForegroundColor Cyan
        
        # Try to remove via winget first
        winget uninstall --id=$app --silent --accept-source-agreements 2>$null
        
        # Also try to remove via PowerShell for Store apps
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like "*$app*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        
        Write-Host "Removed $app" -ForegroundColor Green
        "REMOVED: $app" | Out-File -FilePath $logFile -Append
    }
    catch {
        Write-Host "Failed to remove $app : $_" -ForegroundColor Red
        "FAILED TO REMOVE: $app - $_" | Out-File -FilePath $logFile -Append
    }
}

Write-Progress -Activity "Removing Bloatware" -Completed
Write-Host "Bloatware removal completed!" -ForegroundColor Green
Write-Host ""

# SECTION 2: INSTALL DESIRED APPS
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "INSTALLING APPLICATIONS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# List of applications to install
$applications = @(
    # Browsers
    "Mozilla.Firefox"
    "Google.Chrome"
    "Vivaldi.Vivaldi"
    
    # Productivity
    "Microsoft.VisualStudioCode"
    "GitHub.GitHubDesktop"
    
    # Media
    "VideoLAN.VLC"
    "Spotify.Spotify"

    # Cloud Storage
    "Microsoft.OneDrive"
    "Apple.iCloud"
    
    # Communication
    "Discord.Discord"

    # Development
    "Python.Python.3.13"
    "OpenJS.NodeJS"
    "CharlesMilette.TranslucentTB"
     
    # Gaming (optional)
    "Valve.Steam"
    "EpicGames.EpicGamesLauncher"
    "Mojang.MinecraftLauncher"
)

# Create a log file
$logFile = "$env:USERPROFILE\Desktop\app_installation_log.txt"
"App Installation Log - $(Get-Date)" | Out-File -FilePath $logFile

# Install applications
$totalApps = $applications.Count
$currentApp = 0

foreach ($app in $applications) {
    $currentApp++
    $progressPercentage = ($currentApp / $totalApps) * 100
    
    Write-Progress -Activity "Installing Applications" -Status "$app ($currentApp of $totalApps)" -PercentComplete $progressPercentage
    
    try {
        Write-Host "Installing $app..." -ForegroundColor Cyan
        winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully installed $app" -ForegroundColor Green
            "SUCCESS: $app installed successfully" | Out-File -FilePath $logFile -Append
        } else {
            Write-Host "Failed to install $app" -ForegroundColor Red
            "FAILED: $app installation failed with exit code $LASTEXITCODE" | Out-File -FilePath $logFile -Append
        }
    }
    catch {
        Write-Host "Error installing $app : $_" -ForegroundColor Red
        "ERROR: $app - $_" | Out-File -FilePath $logFile -Append
    }
    
    Write-Host "" # Empty line for better readability
}

# SECTION 3: SYSTEM OPTIMIZATION
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "PERFORMING SYSTEM OPTIMIZATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Post-installation cleanup and system updates
Write-Host "Running Windows Update..." -ForegroundColor Yellow
Try {
    Get-Command -Name UsoClient -ErrorAction Stop
    Start-Process -FilePath "UsoClient.exe" -ArgumentList "ScanInstallWait" -Wait
    "Windows Update scan completed" | Out-File -FilePath $logFile -Append
} Catch {
    Write-Host "Windows Update client command not available." -ForegroundColor Yellow
    "Windows Update scan skipped" | Out-File -FilePath $logFile -Append
}

# Cleanup temp files
Write-Host "Cleaning temporary files..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
"Temporary files cleaned" | Out-File -FilePath $logFile -Append

# Disable some telemetry and data collection (optional)
Write-Host "Adjusting privacy settings..." -ForegroundColor Yellow
# Disable Advertising ID
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
# Disable app launch tracking
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -PropertyType DWord -Force | Out-Null
"Privacy settings adjusted" | Out-File -FilePath $logFile -Append

Write-Host "Installation and system setup completed! Check log file at: $logFile" -ForegroundColor Green
Write-Host "Your system may need to restart to finish some installations." -ForegroundColor Yellow