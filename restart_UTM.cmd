@echo OFF

REM Check admin privilegies
NET SESSION >NUL 
if %errorlevel% NEQ 0 (
    echo �ॡ����� �ࠢ� �����������.
    pause
    exit
)

set main_fail = 0
set mon_fail = 0
set upd_fail = 0

echo ����� �㦡 UTM:
for /F "tokens=3 delims=: " %%H in ('sc query "Transport" ^| findstr "        ����ﭨ�"') do (
  if /I "%%H" NEQ "RUNNING" (
      echo     ��㦡� Transport �� ����饭�.
      set main_fail = 1
  ) else (
      echo     ��㦡� Transport ����饭�.
  ) 
for /F "tokens=3 delims=: " %%H in ('sc query "Transport-Monitoring" ^| findstr "        ����ﭨ�"') do (
  if /I "%%H" NEQ "RUNNING" (
      echo     ��㦡� Transport-Monitoring �� ����饭�.
      set mon_fail = 1
  ) else (
      echo     ��㦡� Transport-Monitoring ����饭�.
  )
for /F "tokens=3 delims=: " %%H in ('sc query "Transport-Updater" ^| findstr "        ����ﭨ�"') do (
  if /I "%%H" NEQ "RUNNING" (
      echo     ��㦡� Transport-Updater �� ����饭�.
      set upd_fail = 1
  ) else (
      echo     ��㦡� Transport-Updater ����饭�.
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