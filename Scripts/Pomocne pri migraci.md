### Ze Zabbix exportu hostu vybrat jen hostname

```
(Get-Content C:\Users\Administrator\Downloads\zbx_export_hosts.json | ConvertFrom-Json ).zabbix_export.hosts.name
```

### K seznamu serveru pridat IP adresu
```
$servers = Get-Content C:\ac\server.css
ForEach ($server in $servers) {
    $ips = ''
    Try {
        $ips = [System.Net.Dns]::GetHostAddresses($server)   
    } Catch {
    }
    Write-Host "$server,$ips"
}
```