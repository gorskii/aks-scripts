param (
    [Parameter(Position=0)]
    [string]
    $server,
    [string]
    $inputFile,
    [string]
    $outputFile
)


[System.Collections.ArrayList]$entries = @()

$count = 0  # Progress Bar counter

if ($inputFile){
    $hosts = Get-Content -Path $inputFile -Encoding UTF8
}
else {
    $hosts = @($server)
}

foreach ($hostName in $hosts) {
    # Remove port from hostName to use HTTPS protocol in legacy server lists
    $hostName = $hostName -replace ":8080" -replace ":9080"

    Write-Progress -Activity "Checking hosts..." -Status "Progress:" -PercentComplete ($count/$hosts.Length*100) -CurrentOperation $hostName

    # Skip commented strings
    if ($hostName[0] -eq '#') {
        $count += 1
        continue
    }

    try {
        $request = Invoke-WebRequest -Uri https://$hostName/resto/get_server_info.jsp -Method Get -ErrorAction Continue
        $content = $request.Content

        $serverName = Select-XML -Content $content -XPath "r/serverName"
        $version = Select-XML -Content $content -XPath "r/version"
        $serverState = Select-XML -Content $content -XPath "r/serverState"
    }
    catch {
        $serverName = "N/A"
        $version = "N/A"
        $serverState = "N/A"
    }

    $entryDict = [ordered]@{
        HostName = $hostName
        ServerName = $serverName
        Version = $version
        ServerState = $serverState
    }

    # Create psobject to store result fields as properties
    $entry = New-Object psobject
    $entry | Add-Member -NotePropertyMembers $entryDict
    
    # Add entry into $entries ArrayList silently
    $entries.Add($entry) | Out-Null  
    
    $count += 1
}

Write-Output $entries | Format-Table -AutoSize

# Export entry as CSV if "-outputFile" is specified. Remove if file 
if ($outputFile) {
    if (Test-Path $outputFile) {
        Remove-Item $outputFile
    }

    foreach ($entry in $entries) {
        Export-Csv -InputObject $entry -Path $outputFile -Append -Encoding UTF8 -Delimiter ";" -Force -NoTypeInformation
    }
}