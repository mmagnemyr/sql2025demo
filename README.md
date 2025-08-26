# sql2025demo

# links
https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver17&tabs=cli&pivots=cs1-bash

# docker pull
docker pull mcr.microsoft.com/mssql/server:2025-latest

# docker run
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=MyPassw0rd!" \
   -p 1433:1433 --name sql1 --hostname sql1 \
   -d \
   mcr.microsoft.com/mssql/server:2025-latest



docker exec -it sql1 "bash"

/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'MyPassw0rd!' -C

## check connection from windows using powershell
# Get WSL eth0 IP
$wslIp = wsl.exe sh -lc "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"
$wslIp
# Quick connectivity test
Test-NetConnection $wslIp -Port 1433

