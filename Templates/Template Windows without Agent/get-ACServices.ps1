<#
.SYNOPSIS
.DESCRIPTION
.NOTES
.LINK
.EXAMPLE
.PARAMETER foo
.PARAMETER bar
#>

<# TODO

#>

[CmdletBinding()]Param (
     [Parameter(Mandatory=$False)] [Alias("Hostname")]   [string]$attrHostName
    ,[Parameter(Mandatory=$False)] [Alias("Pass")]       [string]$attrPass
    ,[Parameter(Mandatory=$False)] [Alias("Username")]   [string]$attrUsername = 'aclab\acmonitor'
    ,[Parameter(Mandatory=$False)] [Alias("PathKey")]    [string]$attrPathKey = '/usr/lib/zabbix/externalscripts/aes.key'
    ,[Parameter(Mandatory=$False)] [Alias("Discovery")]  [int]$attrDiscovery = 1
    ,[Parameter(Mandatory=$False)] [Alias("ServiceName")]  [string]$attrServiceName
)

# inicialization
Set-StrictMode -Version latest
$global:ErrorActionPreference = 'Stop'
$Error.Clear()

# convert password
$SecurePassword = $attrPass | ConvertTo-SecureString -Key (Get-Content $attrPathKey) 

# create credential
$credential = New-Object System.Management.Automation.PSCredential($attrUsername, $SecurePassword) 

Try 
{
    $session = New-PSSession -ComputerName $attrHostName -Credential $credential -Authentication Negotiate -ErrorAction Stop
}
Catch
{
    Write-Host "Chyba => $($Error[0])"
    Exit
}

# Discovery mode
If ($attrDiscovery -eq 1) {
	Invoke-Command -Session $session -ScriptBlock {
		$services = Get-Service | Where {$_.StartType -eq "Automatic" -or $_.StartType -eq "AutomaticDelayedStart"}
		$returnJson = '{"data": ['
		ForEach ($service In $services) {
			$returnJson += '{"{#SERVICENAME}":"' + $service.Name + '","{#SERVICEDISPLAYNAME}":"' + $service.DisplayName + '" },'
		}
		# odeber posledni znak
		$returnJson = $returnJson.Substring(0,$returnJson.Length-1)
		$returnJson += ']}'
		$returnJson
	}
} ElseIf ($attrServiceName) {
	Invoke-Command -Session $session -ScriptBlock {
		$service = Get-Service -Name $args[0]
#		$service
		If ($service.status -ne 'Running') {
			Write-Host 0
		} Else {
			Write-Host 1
		}
	} -args $attrServiceName
}



Remove-PSSession $session
