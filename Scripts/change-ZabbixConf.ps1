<#
.SYNOPSIS
.DESCRIPTION
.NOTES
.LINK
.EXAMPLE
.PARAMETER foo
.PARAMETER bar
#>

[CmdletBinding()]Param (
    [Parameter(Mandatory=$False)]  [array]$attrComputers
)

ForEach ($computer in $attrComputers) {

    Write-Verbose "Set -> $computer"
    Invoke-Command -ComputerName $computer -ScriptBlock {
        If (Get-Service 'Zabbix Agent' | Where {$_.StartType -eq 'Automatic'}) {
            If (Test-Path -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf') {
                Write-Host  'Agent v1'
                (Get-Content 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw).Replace("Server=zabbix.netadmin.cz",'Server=zabbix.netadmin.cz,10.140.10.32') | Set-Content 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
                (Get-Content 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'  -Raw).Replace("ServerActive=zabbix.netadmin.cz:10052`r`n","ServerActive=zabbix.netadmin.cz:10052,10.140.10.32`r`n") | Set-Content 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
                Write-Host  'Restart Agent v1'
                Restart-Service 'Zabbix Agent'
            } 
        }

        If (Get-Service 'Zabbix Agent 2' | Where {$_.StartType -eq 'Automatic'}) {
            If (Test-Path -Path 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf') {
                Write-Host  'Agent v2'
                (Get-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf' -Raw).Replace("Server=zabbix.netadmin.cz`r`n","Server=zabbix.netadmin.cz,10.140.10.32`r`n") | Set-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf' 
                (Get-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf' -Raw).Replace("ServerActive=zabbix.netadmin.cz:10052`r`n","ServerActive=zabbix.netadmin.cz:10052,10.140.10.32`r`n") | Set-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf' 
                Write-Host  'Restart Agent v2'
                Restart-Service 'Zabbix Agent 2'
            }
        }
    }
}
