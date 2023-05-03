$computers = @('BIOPDC01','BIOPDC02','BIOPMGMT01','BIOPRS01','BIOPRS02')

ForEach ($computer in $computers) {
    $path = '\\' + $computer + '\c$\Program Files\Zabbix Agent 2\zabbix_agent2.d\'
    $path
    copy C:\AC\Config\* $path 

    
    Invoke-Command -ComputerName $computer -ScriptBlock {
        Restart-Service 'Zabbix Agent 2'
    }


}

