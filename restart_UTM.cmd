@echo OFF

REM Check admin privilegies
NET SESSION >NUL 
if %errorlevel% NEQ 0 (
    echo Требуются права администратора.
    pause
    exit
)

set main_fail = 0
set mon_fail = 0
set upd_fail = 0

echo Статус служб UTM:
for /F "tokens=3 delims=: " %%H in ('sc query "Transport" ^| findstr "        Состояние"') do (
  if /I "%%H" NEQ "RUNNING" (
      echo     Служба Transport не запущена.
      set main_fail = 1
  ) else (
      echo     Служба Transport запущена.
  ) 
for /F "tokens=3 delims=: " %%H in ('sc query "Transport-Monitoring" ^| findstr "        Состояние"') do (
  if /I "%%H" NEQ "RUNNING" (
      echo     Служба Transport-Monitoring не запущена.
      set mon_fail = 1
  ) else (
      echo     Служба Transport-Monitoring запущена.
  )
for /F "tokens=3 delims=: " %%H in ('sc query "Transport-Updater" ^| findstr "        Состояние"') do (
  if /I "%%H" NEQ "RUNNING" (
      echo     Служба Transport-Updater не запущена.
      set upd_fail = 1
  ) else (
      echo     Служба Transport-Updater запущена.
  )

if  %main_fail% NEQ 1 (
    net stop "Transport"
)
if %mon_fail% NEQ 1 (
    net stop "Transport-Monitoring"   
)
if %upd_fail% NEQ 1 (
    net stop "Transport-Updater"
)
    net start "Transport-Updater"
    net start "Transport-Monitoring"
    net start "Transport"

timeout 5