$computers = @('','','')

ForEach ($computer in $computers) {

    $computer
    Invoke-Command -ComputerName $computer -ScriptBlock {
        (Get-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf').Replace('172.30.2.30','172.30.63.30') | Set-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf' ; Restart-Service 'Zabbix Agent 2'
    }
}
