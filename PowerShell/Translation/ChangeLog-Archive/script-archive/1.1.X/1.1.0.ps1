# Define file paths
$fileListUrl = "https://pvz2cdn.ditwan.cn/ad/res_shipping/file_list.txt"
$downloadPath = "C:\Users\evilhack28\Desktop\TRANSLATION SCRIPT\NEW\file_list.txt"
$existingFilePath = "C:\Users\evilhack28\Desktop\TRANSLATION SCRIPT\OLD\file_list.txt"  # Checking in OLD folder

# Define URL and path for downloading the new file when MD5s do not match
$newFileUrl = "https://pvz2cdn.ditwan.cn/ad/res_shipping/pvz2_l.txt"
$newFilePath = "C:\Users\evilhack28\Desktop\TRANSLATION SCRIPT\NEW\pvz2_l.txt"
$existingNewFilePath = "C:\Users\evilhack28\Desktop\TRANSLATION SCRIPT\OLD\pvz2_l.txt"

# Function to download the file and display download time and file size
Function Download-File {
    param (
        [string]$url,
        [string]$destination
    )

    try {
        # Measure download time
        $downloadTime = Measure-Command {
            Invoke-WebRequest -Uri $url -OutFile $destination
        }

        # Get file size in bytes and convert to KB or MB for readability
        $fileSizeBytes = (Get-Item $destination).Length
        $fileSize = if ($fileSizeBytes -gt 1MB) {
            "{0:N2} MB" -f ($fileSizeBytes / 1MB)
        } elseif ($fileSizeBytes -gt 1KB) {
            "{0:N2} KB" -f ($fileSizeBytes / 1KB)
        } else {
            "$fileSizeBytes Bytes"
        }

        # Output download time in seconds with milliseconds (e.g., 1.365)
        $downloadSeconds = "{0:N3}" -f $downloadTime.TotalSeconds
        Write-Host "File successfully downloaded" -ForegroundColor Green
        Write-Host "Download Time: $downloadSeconds seconds"
        Write-Host "File Size: $fileSize"
    } catch {
        Write-Host "Error downloading: $_" -ForegroundColor Red
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
        Write-Host "File not found: $filePath"  -ForegroundColor Red
        return $null
    }
}

# Initialize retry count for file_list.txt
$retryCount = 0
$maxRetries = 25

# Loop until the MD5 hashes do not match
do {
    # Check if file_list.txt exists in the OLD folder before proceeding
    if (-not (Test-Path $existingFilePath)) {
        Write-Host "There is no other file for comparing MD5 of file_list.txt" -ForegroundColor Red
        # Check every 1 second until the file is found
        Start-Sleep -Seconds 1
        continue
    }

    # Check if pvz2_l.txt exists in the OLD folder before comparing MD5
    if (-not (Test-Path $existingNewFilePath)) {
        Write-Host "There is no other file for comparing MD5 of pvz2_l.txt!" -ForegroundColor Red
        # Check every 1 second until the file is found
        Start-Sleep -Seconds 1
        continue
    }

    # Download the file_list.txt from the URL
    Download-File -url $fileListUrl -destination $downloadPath

    # Compute MD5 hashes of the downloaded file and the existing file
    $downloadedFileMD5 = Get-FileMD5 -filePath $downloadPath
    $existingFileMD5 = Get-FileMD5 -filePath $existingFilePath

    # Compare the MD5 hashes
    if ($downloadedFileMD5 -and $existingFileMD5) {
        if ($downloadedFileMD5 -ne $existingFileMD5) {
            Write-Host "MD5 of file_list.txt does not match! Downloading new pvz2_l.txt..." -ForegroundColor Green
            
            # Download the new pvz2_l.txt file
            Download-File -url $newFileUrl -destination $newFilePath
            
            # Check MD5 of the downloaded pvz2_l.txt
            $newFileMD5 = Get-FileMD5 -filePath $newFilePath
            if ($newFileMD5) {
                Write-Host "New pvz2_l.txt downloaded successfully with MD5: $newFileMD5" -ForegroundColor Green
            } else {
                Write-Host "Failed to download new pvz2_l.txt. Check the URL or network connection." -ForegroundColor Red
            }

            break  # Exit the loop after detecting changes and handling them
        } else {
            Write-Host "MD5 match for file_list.txt. Retrying..." -ForegroundColor Green
        }
    }

    # Check every 1 second
    Start-Sleep -Seconds 1

} while ($true)
