$base_url = "http://file.aks.support/"

$path = "C:\Distr\"
$file = "Setup.iikoCard5.POS.exe"
$verfile = "version"

$file_path = -join($path + $file)

# Проверка наличия каталога и текущей версии
$path_exist = Test-Path $path
if(-not $path_exist) {
    New-Item -Path $path -ItemType "directory"
}

# Инициализация веб-клиента
$WebClient = New-Object System.Net.WebClient
$WebClient.BaseAddress = $base_url

# Получаем версию файла из облака
Try {
	$remote_ver = $WebClient.DownloadString($verfile)
    Write-Host ("Версия iikoCard5 POS на сервере: {0}" -f $remote_ver)
} 
Catch {
	Write-Warning "$($error[0])"
    Write-Warning "Не удаётся получить информацию о версии с сервера. Проверьте подключение."
    exit
}
# TODO # Красиво обработать исключение

# Получаем текущую версию программы
Try {
    $current_ver =  Get-Package "iikoCard5 POS" | Select-Object -ExpandProperty "Version" 
    
    Write-Host ("Текущая версия iikoCard5 POS: {0}" -f $current_ver)

    $current_ver_int = [int]($current_ver -replace '[\.]+', '')
    $remote_ver_int = [int]($remote_ver -replace '[\.]+', '')

    if ($remote_ver_int -le $current_ver_int) {
        Write-Host "Текущая версия актуальна"
        exit
    }
}
Catch {
    Write-Warning "iikoCard5 POS не установлен"
}


Write-Host ("Загрузка iikoCard5 POS")

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
# TODO Загрузка дистрибутива во временный файл, при успешной загрузке замена имеющегося в $file_path дистрибутива
Try {
	$WebClient.DownloadFileAsync($file, $file_path)
} 
Catch {
	Write-Warning "$($error[0])"
}

# Отрисовываем прогрессбар для загружаемого файла
While (-not $isDownloaded){
    $percent = $Global:Data.SourceArgs.ProgressPercentage
    $total = $Global:Data.SourceArgs.TotalBytesToReceive/1024
    $received = $Global:Data.SourceArgs.BytesReceived/1024
    If ($percent -ne $null) {
        Write-Progress -Id 1 -Activity ("Загружается {0}" -f $file) `
        -Status ("{0} Kb \ {1} Kb, {2}%" -f [int]$received,[int]$total,$percent) -PercentComplete $percent
    }
}

# Если дистрибутив успешно загружен, запускаем установку в пассивном режиме
If ($isDownloaded) {
    $version_card = (Get-Item $file_path).VersionInfo.FileVersion
    Write-Host ("Загрузка iikoCard5 POS завершена, загруженная версия: {0}" -f $version_card)
    Write-Host "Запускается установка..."
    Start-Process $file_path -ArgumentList "/passive"
}

# Удаляем созданные события
Get-EventSubscriber | Unregister-Event

# TODO #
# Батник, который скачивает скрипт и запускает. Установить политику выполнения.
# Закачка должна успешно перезапускаться, если скрипт был аварийно завершён.
# Запуск службы iikoCard