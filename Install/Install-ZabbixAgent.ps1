<#
.SYNOPSIS
	Install Zabbix Agent MSI Remote
.DESCRIPTION
.NOTES
	SVN: $Rev$
		$Date$
		$Author$
.LINK
.EXAMPLE
.PARAMETER attrServername
#>

[CmdletBinding()]Param (
    [Parameter(Mandatory=$True,Position=1)] [Alias("ServerName")] [string]$attrServername
    ,[Parameter(Mandatory=$False,Position=2)] [Alias("FileMSI")] [string]$attrFileMSI = '\\nlt-dc01\Install\zabbix_agent-4.2.6-win-amd64-openssl.msi'
)

$arguments = "\\$attrServername -d -s msiexec /i $attrFileMSI /l*v c:\zabbix_agent_install_log.txt /qn SERVER=nlt-zabbix01.nemocnice-lt.cz SERVERACTIVE=nlt-zabbix01.nemocnice-lt.cz"

Start-Process C:\install\PsExec64.exe -ArgumentList $arguments -Wait

