param(
    [string]$date
)

$apiKey     = 'YOUR_API_KEY_HERE'  # Replace with your actual API key
$targetDate = if ($date) { $date } else { (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') }
$fileName   = "LL_$($targetDate -replace '-', '_').txt"
$logFile    = "FetchLog_$($targetDate -replace '-', '_').txt"

# Initialize an empty array to hold all lifelog contents
$allContents = @()

# Initialize logging divider and run metadata
$logDivider = '----- Script Run '
$scriptStartTime = Get-Date
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Add separator line and new run header
Add-Content -Path $logFile -Value "`n`n==========================================="
Add-Content -Path $logFile -Value "`n$logDivider START -----"
Add-Content -Path $logFile -Value "Start Time : $($scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Add-Content -Path $logFile -Value "Date        : $targetDate"

# Start with no cursor
$cursor = $null
$pageNumber = 1
$totalPages = $null
$successfulRequests = 0
$exitReason = "Script completed successfully"

# Function to decode base64 cursor
function Decode-Cursor {
    param([string]$cursor)
    try {
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($cursor))
        $json = $decoded | ConvertFrom-Json
        return $json.cursorValue
    } catch {
        return "Failed to decode cursor"
    }
}

do {
    # Build the URL with the cursor if it exists
    $url = "https://api.limitless.ai/v1/lifelogs?date=$targetDate&timezone=UTC&includeHeadings=true&includeMarkdown=false&limit=3"
    if ($cursor) {
        $url += "&cursor=$cursor"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] Requesting Page $pageNumber. URL: $url"
    if ($cursor) {
        $decodedCursor = Decode-Cursor -cursor $cursor
        Add-Content -Path $logFile -Value "               Cursor Value: $decodedCursor"
    }

    # Add error handling and retry logic for 504 errors
    $maxRetries = 10
    $retryCount = 0
    $success = $false
    
    do {
        try {
            $requestStartTime = Get-Date
            $response = Invoke-RestMethod -Uri $url -Headers @{ "X-API-Key" = $apiKey } -TimeoutSec 30
            $requestEndTime = Get-Date
            $requestDuration = $requestEndTime - $requestStartTime
            
            # Log successful response
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Add-Content -Path $logFile -Value "[$timestamp] Success Page $pageNumber. Duration: $($requestDuration.TotalSeconds) s"
            Add-Content -Path $logFile -Value "               Meta Response:"
            Add-Content -Path $logFile -Value "               - Total Count: $($response.meta.lifelogs.count)"
            Add-Content -Path $logFile -Value "               - Has Next Page: $($response.meta.lifelogs.nextCursor -ne $null)"
            Add-Content -Path $logFile -Value "               - Items in Response: $($response.data.lifelogs.Count)"
            
            if (-not $totalPages) {
                $totalPages = [math]::Ceiling($response.meta.lifelogs.count / 3)
                Add-Content -Path $logFile -Value "               - Total Pages: $totalPages"
            }
            
            $success = $true
            $successfulRequests++
            break
        } catch {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            if ($_.Exception.Response.StatusCode -eq 504) {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Add-Content -Path $logFile -Value "[$timestamp] Received 504 error. Retry attempt $retryCount of $maxRetries. Waiting 10 seconds..."
                    Start-Sleep -Seconds 10
                } else {
                    $exitReason = "Max retries ($maxRetries) reached for 504 errors"
                    Add-Content -Path $logFile -Value "[$timestamp] $exitReason. Exiting."
                    $cursor = $null    # stop outer loop
                    $success = $true  # exit retry loop
                    break
                }
            } else {
                $exitReason = "Unexpected error: $_"
                Add-Content -Path $logFile -Value "[$timestamp] $exitReason"
                throw
            }
        }
    } while (-not $success)

    # Extract the contents from this page
    $contents = $response.data.lifelogs | ForEach-Object { $_.contents }
    $allContents += $contents

    # Update the cursor for the next iteration
    $cursor = $response.meta.lifelogs.nextCursor
    if ($cursor) {
        $decodedCursor = Decode-Cursor -cursor $cursor
        Add-Content -Path $logFile -Value "               Next Cursor Value: $decodedCursor"
    } else {
        $exitReason = "No more pages to fetch"
    }

    $pageNumber++
    Start-Sleep -Seconds 20
} while ($cursor)

# Format the contents as requested and write to file
$allContents | ForEach-Object {
    if ($_.type -eq "heading1") {
        "# $($_.content)"
    } elseif ($_.type -eq "heading2") {
        "## $($_.content)"
    } else {
        "$(if ($_.speakerName) { $_.speakerName } else { 'Unknown' }), $($_.startTime -replace '.*T(\d{2}:\d{2}:\d{2}).*', '$1'), $($_.content)"
    }
} | Out-File -FilePath $fileName

# Record end time and calculate duration
$stopwatch.Stop()
$scriptEndTime = Get-Date
Add-Content -Path $logFile -Value "`n$logDivider END -----"
Add-Content -Path $logFile -Value "End Time   : $($scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Add-Content -Path $logFile -Value "Run Time   : $($stopwatch.Elapsed.ToString())"
Add-Content -Path $logFile -Value "Pages Fetched : $($pageNumber-1) / $totalPages"
Add-Content -Path $logFile -Value "Successful Requests: $successfulRequests"
Add-Content -Path $logFile -Value "Items Processed: $($allContents.Count)"
Add-Content -Path $logFile -Value "Exit Reason: $exitReason"

Write-Host "Log output has been saved to $logFile" 