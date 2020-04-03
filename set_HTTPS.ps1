<#
.SYNOPSIS

    Set connection protocol to HTTPS for iikoFront, iikoOffice and iikoChain

.DESCRIPTION

    This script replaces HTTP connection strings with HTTPS ones in iikoFront's 'config.xml' and iikoDelivery plugin's 'deliveryPluginConfig.xml'.
    It also searches for all available BackOffice config files in '%AppData%\iiko' folder and sets HTTPS protocol for every HTTP entry.

    NOTE: Only iikoCloud entries (iiko.it:8080 or iiko.it:9080) are affected.

#>

$PATH_RMS = "$env:APPDATA\iiko\Rms"
$PATH_CHAIN = "$env:APPDATA\iiko\Chain"
$PATH_CASHSERVER = "$env:APPDATA\iiko\CashServer"

Function SetHTTPS([String]$path){
    if (Test-Path $path)
    {
        $configFile = Get-Content -ErrorAction Stop -Path $path
        if (($configFile | Select-String "iiko.it:8080/resto") -or (($configFile | Select-String "iiko.it") -and (($configFile | Select-String "<Port>8080</Port>") -or ($configFile | Select-String "<Port>9080</Port>"))))
        {
            $configFile = $configFile -replace "<serverUrl>http://", "<serverUrl>https://"
            $configFile = $configFile -replace "<Protocol>http</Protocol>", "<Protocol>https</Protocol>"
            $configFile = $configFile -replace "<Port>8080</Port>", "<Port>443</Port>"
            $configFile = $configFile -replace "<Port>9080</Port>", "<Port>443</Port>"
            $configFile = $configFile -replace "iiko.it:8080/resto", "iiko.it/resto"
            $configFile -replace "iiko.it:9080/resto", "iiko.it/resto" | Out-File $path -Encoding default -ErrorAction Stop
            Write-Host "Succsessfully set HTTPS entries in '$path'."
        }
        else
        {
            Write-Host "No HTTP iikoCloud entries found in '$path'."
        }
    }
    else
    {
        Write-Host "File '$path' does not exist."
    }
    return
} #end SetHTTPS

if (Test-Path $PATH_RMS)
{
    ForEach ($FolderName in Get-ChildItem $PATH_RMS) {
        $path = "$PATH_RMS\$FolderName\config\backclient.config.xml"
        SetHTTPS($path)
    }
}
else
{
    Write-Host "Path '$PATH_RMS' does not exist."
}

if (Test-Path $PATH_CHAIN)
{
    ForEach ($FolderName in Get-ChildItem $PATH_CHAIN) {
        $path = "$PATH_CHAIN\$FolderName\config\backclient.config.xml"
        SetHTTPS($path)
    }
}
else
{
    Write-Host "Path '$PATH_CHAIN' does not exist."
}

if (Test-Path $PATH_CASHSERVER)
{
    SetHTTPS("$PATH_CASHSERVER\config.xml")
    SetHTTPS("$PATH_CASHSERVER\PluginConfigs\Resto.Front.Api.Delivery\deliveryPluginConfig.xml")
}
else
{
    Write-Host "Path '$PATH_CASHSERVER' does not exist."
}
Start-Sleep 10
