$base_url = "http://file.aks.support/"

$path = "C:\Distr\"
$file = "Setup.iikoCard5.POS.exe"
$verfile = "version_pos"

$path_exist = Test-Path $path
$file_path = -join($path + $file)
$file_exist = Test-Path $file_path

#region Проверка наличия каталога и текущей версии

if(-not $path_exist) {
    New-Item -Path $path -ItemType "directory"
}

$current_ver = Get-Package "iikoCard5 POS" | Select-Object -ExpandProperty "Version" 
if ($current_ver) {
    Write-Host ("Текущая версия iikoCard5 Pos {0}" -f $current_ver)
}
#endregion

$WebClient = New-Object System.Net.WebClient
$WebClient.BaseAddress = $base_url
# Получаем версию из облака
Try {
	$remote_ver = $WebClient.DownloadString($verfile)
} 
Catch {
	Write-Warning "$($error[0])"
}

if ($remote_ver -eq $current_ver) {
    Write-Host "Текущая версия актуальна"
} else 
{
    Write-Host ("Загрузка iikoCard5 Pos версии {0}" -f $remote_ver)
}

# Загружаем дистрбутив с сервера

# Удаляем события отслеживания состояния загрузки
Get-EventSubscriber | Unregister-Event
$Global:isDownloaded = $false

# Событие окончания загрузки
Register-ObjectEvent -InputObject $WebClient -EventName DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileCompleted -Action {
    $Global:isDownloaded = $true
} | Out-Null

# Событие прогресса загрузки
Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
    $Global:Data = $event   
} | Out-Null

# Загрузка файла
Try {
	$WebClient.DownloadFileAsync($file, $file_path)
} 
Catch {
	Write-Warning "$($error[0])"
}

# Орисовываем прогрессбар для загружаемого файла
While (-not $isDownloaded){
    $percent = $Global:Data.SourceArgs.ProgressPercentage
    $total = $Global:Data.SourceArgs.TotalBytesToReceive/1024
    $received = $Global:Data.SourceArgs.BytesReceived/1024
    If ($percent -ne $null) {
        Write-Progress -Id 1 -Activity ("Загружается {0}" -f $file) `
        -Status ("{0} Kb \ {1} Kb, {2}%" -f [int]$received,[int]$total,$percent) -PercentComplete $percent
    }
}

If ($isDownloaded) {
    $version_card = (Get-Item $file_path).VersionInfo.FileVersion
    write-host ("Загрузка iikoCard5 Pos завершена, загруженная версия: {0}" -f $version_card)
}

# Удаляем созданные события
Get-EventSubscriber | Unregister-Event

# TODO #
# Батник, который скачивает скрипт и запускает. Установить политику выполнения.
# Загрузка дистрибутива во временный файл, при успешной загрузке замена имеющегося в C:\Distr дистрибутива
# Проверить установленную версию, сверить с серверной. Если новая, скачать и установить.
# Запуск службы iikoCard