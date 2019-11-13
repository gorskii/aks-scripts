---

## get_server_info.ps1

Gets iikoRMS server version and state.

### Description

**get_server_info** script is using [Invoke-WebRequest](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest) Cmdlet on /resto/get_server_info.jsp
to get server version and its current state.
It shows 'N/A' if host is unreachable.

Accepts list of hostnames as `-inputFile` or a single hostname as a first argument.
Writes results to console output and to CSV file, if `-outputFile` argument is specified.

### Usage

    ./get_server_info.ps1 server.iiko.it:8080

    ./get_server_info.ps1 -inputFile servers.txt -outputFile result.csv
