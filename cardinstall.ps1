$base_url = "http://file.aks.support/"

$path = "C:\Distr\"
$file = "Setup.iikoCard5.POS.exe"
$verfile = "version"

$file_path = -join($path + $file)

# �������� ������� �������� � ������� ������
$path_exist = Test-Path $path
if(-not $path_exist) {
    New-Item -Path $path -ItemType "directory"
}

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
    exit
}
# TODO # ������� ���������� ����������

# �������� ������� ������ ���������
Try {
    $current_ver =  Get-Package "iikoCard5 POS" | Select-Object -ExpandProperty "Version" 
    
    Write-Host ("������� ������ iikoCard5 POS: {0}" -f $current_ver)

    $current_ver_int = [int]($current_ver -replace '[\.]+', '')
    $remote_ver_int = [int]($remote_ver -replace '[\.]+', '')

    if ($remote_ver_int -le $current_ver_int) {
        Write-Host "������� ������ ���������"
        exit
    }
}
Catch {
    Write-Warning "iikoCard5 POS �� ����������"
}


Write-Host ("�������� iikoCard5 POS")

# ��������� ���������� � �������

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
# TODO �������� ������������ �� ��������� ����, ��� �������� �������� ������ ���������� � $file_path ������������
Try {
	$WebClient.DownloadFileAsync($file, $file_path)
} 
Catch {
	Write-Warning "$($error[0])"
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

# ���� ����������� ������� ��������, ��������� ��������� � ��������� ������
If ($isDownloaded) {
    $version_card = (Get-Item $file_path).VersionInfo.FileVersion
    Write-Host ("�������� iikoCard5 POS ���������, ����������� ������: {0}" -f $version_card)
    Write-Host "����������� ���������..."
    Start-Process $file_path -ArgumentList "/passive"
}

# ������� ��������� �������
Get-EventSubscriber | Unregister-Event

# TODO #
# ������, ������� ��������� ������ � ���������. ���������� �������� ����������.
# ������� ������ ������� ���������������, ���� ������ ��� �������� ��������.
# ������ ������ iikoCard