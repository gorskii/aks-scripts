$base_url = "http://file.aks.support/"

$aks_path = "$env:APPDATA\AKS\"
$path = "C:\Distr\"
$file = "Setup.iikoCard5.POS.exe"
$verfile = "version"

$file_path = -join($path + $file)
$aks_file_path = -join($aks_path + $file)

# ������������� ������� �������
$aks_path_exist = Test-Path $aks_path
if (-not $aks_path_exist) {
    New-Item -Path $aks_path -ItemType "directory" | Out-Null
}
# TODO # �� ��������, ����������� � ����� �������. �������� ������������ ���������� ����.
# Set-Location -Path $aks_path

# ������������� ���-�������
$WebClient = New-Object System.Net.WebClient
$WebClient.BaseAddress = $base_url

# �������� ������ ����� �� ������
Try {
	$remote_ver = $WebClient.DownloadString($verfile)
    Write-Host ("������ iikoCard5 POS �� �������: {0}" -f $remote_ver)
} 
Catch {
	Write-Warning "$($error[0])"
    Write-Warning "�� ������ �������� ���������� � ������ � �������. ��������� �����������."
    Start-Sleep -Seconds 5
    exit
}

# �������� ������� ������ ���������
# TODO # ������ ����������� ����� �����, Get-WmiObject ������������ ��� ������������� � Windows 7
$current_ver = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name Like 'iikoCard5 POS%'" | Select-Object -ExpandProperty "Version" 

if ($current_ver) {
    Write-Host ("������� ������ iikoCard5 POS: {0}" -f $current_ver)

    $current_ver_int = [int]($current_ver -replace '[\.]+', '')
    $remote_ver_int = [int]($remote_ver -replace '[\.]+', '')

    if ($remote_ver_int -le $current_ver_int) {
        Write-Host "������� ������ ���������"
        Start-Sleep -Seconds 5
        exit
    }
} else {
    Write-Host "iikoCard5 POS �� ����������"
}

# ��������� ���������� � �������
Write-Host ("�������� iikoCard5 POS...")

# ������� ������� ������������ ��������� ��������
Get-EventSubscriber | Unregister-Event
$Global:isDownloaded = $false

# ������� ��������� ��������
Register-ObjectEvent -InputObject $WebClient -EventName DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileCompleted -Action {
    $Global:isDownloaded = $true
} | Out-Null

# ������� ��������� ��������
Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
    $Global:Data = $event   
} | Out-Null

# �������� �����
Try {
	$WebClient.DownloadFileAsync($file, $aks_file_path)
}
Catch {
    Write-Warning "$($error[0])"
    Write-Warning "�� ������ ��������� �����������. ��������� �����������."
    Start-Sleep -Seconds 5
    exit
}

# ������������ ����������� ��� ������������ �����
While (-not $isDownloaded){
    $percent = $Global:Data.SourceArgs.ProgressPercentage
    $total = $Global:Data.SourceArgs.TotalBytesToReceive/1024
    $received = $Global:Data.SourceArgs.BytesReceived/1024
    If ($percent -ne $null) {
        Write-Progress -Id 1 -Activity ("����������� {0}" -f $file) `
        -Status ("{0} Kb \ {1} Kb, {2}%" -f [int]$received,[int]$total,$percent) -PercentComplete $percent
    }
}

# ���� ����������� ������� ��������, �������� ��� � ������� $path � ��������� ��������� � ��������� ������
If ($isDownloaded) {
    # �������� ������� �������� � ������� ������
    $path_exist = Test-Path $path
    if(-not $path_exist) {
        New-Item -Path $path -ItemType "directory" | Out-Null
    }
    Move-Item -Path $aks_file_path -Destination $file_path -Force
    $version_card = (Get-Item $file_path).VersionInfo.FileVersion
    Write-Host ("�������� iikoCard5 POS ���������, ����������� ������: {0}" -f $version_card)
    Write-Host "����������� ���������..."
    Start-Process $file_path -ArgumentList "/passive"
    Start-Sleep -Seconds 5
}

# ������� ��������� �������
Get-EventSubscriber | Unregister-Event

# TODO #
# ������� ������ ������� ���������������, ���� ������ ��� �������� ��������.
# ������ ���� ������� ����������, ���� ������ �������� �� ����� �������� �����.
# ����������� �� ������������ �� Windows 7 � ��� ������ ������� �� install_card.cmd