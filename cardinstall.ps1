$base_url = "http://file.aks.support/"

$aks_path = "$env:APPDATA\AKS\"
$path = "C:\Distr\"
$file = "Setup.iikoCard5.POS.exe"
$verfile = "version"

$file_path = -join($path + $file)
$aks_file_path = -join($aks_path + $file)

# Устанавливаем рабочий каталог
$aks_path_exist = Test-Path $aks_path
if (-not $aks_path_exist) {
    New-Item -Path $aks_path -ItemType "directory" | Out-Null
}
# TODO # не работает, срабатывает в конце скрипта. Временно используются абсолютные пути.
# Set-Location -Path $aks_path

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
    Start-Sleep -Seconds 5
    exit
}

# Получаем текущую версию программы
# TODO # Запрос выполняется очень долго, Get-WmiObject используется для совместимости с Windows 7
$current_ver = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name Like 'iikoCard5 POS%'" | Select-Object -ExpandProperty "Version" 

if ($current_ver) {
    Write-Host ("Текущая версия iikoCard5 POS: {0}" -f $current_ver)

    $current_ver_int = [int]($current_ver -replace '[\.]+', '')
    $remote_ver_int = [int]($remote_ver -replace '[\.]+', '')

    if ($remote_ver_int -le $current_ver_int) {
        Write-Host "Текущая версия актуальна"
        Start-Sleep -Seconds 5
        exit
    }
} else {
    Write-Host "iikoCard5 POS не установлен"
}

# Загружаем дистрбутив с сервера
Write-Host ("Загрузка iikoCard5 POS...")

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
	$WebClient.DownloadFileAsync($file, $aks_file_path)
}
Catch {
    Write-Warning "$($error[0])"
    Write-Warning "Не удаётся загрузить дистрибутив. Проверьте подключение."
    Start-Sleep -Seconds 5
    exit
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

# Если дистрибутив успешно загружен, помещаем его в каталог $path и запускаем установку в пассивном режиме
If ($isDownloaded) {
    # Проверка наличия каталога и текущей версии
    $path_exist = Test-Path $path
    if(-not $path_exist) {
        New-Item -Path $path -ItemType "directory" | Out-Null
    }
    Move-Item -Path $aks_file_path -Destination $file_path -Force
    $version_card = (Get-Item $file_path).VersionInfo.FileVersion
    Write-Host ("Загрузка iikoCard5 POS завершена, загруженная версия: {0}" -f $version_card)
    Write-Host "Запускается установка..."
    Start-Process $file_path -ArgumentList "/passive"
    Start-Sleep -Seconds 5
}

# Удаляем созданные события
Get-EventSubscriber | Unregister-Event

# TODO #
# Закачка должна успешно перезапускаться, если скрипт был аварийно завершён.
# Должен быть таймаут соединения, если пропал интернет во время загрузки файла.
# Прогрессбар не отображается на Windows 7 и при вызове скрипта из install_card.cmd