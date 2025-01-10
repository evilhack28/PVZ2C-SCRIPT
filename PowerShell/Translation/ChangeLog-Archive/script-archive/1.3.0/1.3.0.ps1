# Define base directory dynamically
$basePath = Join-Path ([Environment]::GetFolderPath("Desktop")) "PVZ2C TRANSLATION"
$newFolderPath = Join-Path $basePath "NEW"
$oldFolderPath = Join-Path $basePath "OLD"

# Create directories if they don't exist
If (-not (Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
If (-not (Test-Path $newFolderPath)) {
    New-Item -ItemType Directory -Path $newFolderPath | Out-Null
}
If (-not (Test-Path $oldFolderPath)) {
    New-Item -ItemType Directory -Path $oldFolderPath | Out-Null
}

# Define file URLs
$fileListUrl = "https://pvz2cdn.ditwan.cn/ad/res_release/file_list.txt"
$newFileUrl = "https://pvz2cdn.ditwan.cn/ad/res_release/pvz2_l.txt"

# Define file paths
$newFileListPath = Join-Path $newFolderPath "file_list.txt"
$newPvz2FilePath = Join-Path $newFolderPath "pvz2_l.txt"
$oldFileListPath = Join-Path $oldFolderPath "file_list.txt"

# Function to download a file and measure time and size
Function Download-File {
    param (
        [string]$url,
        [string]$destination
    )

    try {
        # Measure download time
        $downloadTime = Measure-Command {
            Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
        }

        # Get file size in bytes
        $fileSizeBytes = (Get-Item $destination).Length

        # Output results
        Write-Host "File downloaded successfully" -ForegroundColor Green
        Write-Host "Download Time: $($downloadTime.TotalSeconds) seconds"
        Write-Host "File Size: $fileSizeBytes bytes"

        return $fileSizeBytes
    } catch {
        Write-Host "Error downloading: $_" -ForegroundColor Red
        return $null
    }
}

# Function to compute MD5 hash of a file
Function Get-FileMD5 {
    param (
        [string]$filePath
    )

    if (Test-Path $filePath) {
        $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
        $fileStream = [System.IO.File]::OpenRead($filePath)
        $hash = $md5.ComputeHash($fileStream)
        $fileStream.Close()
        return [BitConverter]::ToString($hash) -replace '-'
    } else {
        Write-Host "File not found: $filePath" -ForegroundColor Red
        return $null
    }
}

# Ensure OLD file_list.txt exists (first-time setup)
If (-not (Test-Path $oldFileListPath)) {
    Write-Host "No file_list.txt in OLD folder. Initializing first-time setup..." -ForegroundColor Yellow
    Download-File -url $fileListUrl -destination $oldFileListPath
}

# Main Loop
Do {
    # Download the latest file_list.txt to the NEW folder
    $newFileSize = Download-File -url $fileListUrl -destination $newFileListPath

    # Compute MD5 hashes for comparison
    $newFileListMD5 = Get-FileMD5 -filePath $newFileListPath
    $oldFileListMD5 = Get-FileMD5 -filePath $oldFileListPath

    If ($newFileListMD5 -and $oldFileListMD5) {
        If ($newFileListMD5 -ne $oldFileListMD5) {
            Write-Host "MD5 mismatch detected for file_list.txt! Updating NEW folder..." -ForegroundColor Green

            # Download pvz2_l.txt to NEW folder and log time/size
            $newPvz2FileSize = Download-File -url $newFileUrl -destination $newPvz2FilePath

            # Update OLD file_list.txt with the NEW version
            Copy-Item -Path $newFileListPath -Destination $oldFileListPath -Force

            Write-Host "Updated files in NEW folder:"
            Write-Host "  file_list.txt: $newFileSize bytes"
            Write-Host "  pvz2_l.txt: $newPvz2FileSize bytes"
            Break
        } else {
            Write-Host "MD5 match for file_list.txt. No updates required." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Error calculating MD5. Ensure files are accessible." -ForegroundColor Red
    }

    Start-Sleep -Seconds 1
} While ($true)
