## get_server_info.ps1

Gets iikoRMS server version and state.

### Description

**get_server_info** script is using [Invoke-WebRequest](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest) Cmdlet on /resto/get_server_info.jsp
to get server version and its current state.
It shows 'N/A' if host is unreachable.

Accepts list of hostnames as `-inputFile` or a single hostname as a first argument.
Writes results to console output and to CSV file, if `-outputFile` argument is specified.

*NOTE: Temporarily works with HTTPS protocol only*

### Usage

    ./get_server_info.ps1 server.iiko.it

    ./get_server_info.ps1 -inputFile servers.txt -outputFile result.csv

- - -

## set_HTTPS.ps1

Set connection protocol to HTTPS for iikoFront, iikoOffice and iikoChain.

### Description

This script replaces HTTP connection strings with HTTPS ones in iikoFront's `config.xml` and iikoDelivery plugin's `deliveryPluginConfig.xml`.
It also searches for all available BackOffice config files in `%AppData%\iiko` folder and sets HTTPS protocol for every HTTP entry.

*NOTE: Only iikoCloud entries (iiko.it:8080 or iiko.it:9080) are affected*

### Usage

    ./set_HTTPS.ps1

You can also use `set_HTTPS.bat` script to download and run the above powershell script with `-executionpolicy RemoteSigned` option set, no admin previlegies required:

    ./set_HTTPS.bat
