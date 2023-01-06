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
    ,[Parameter(Mandatory=$False)] [Alias("PathScript")] [string]$attrPathScript = '/usr/lib/zabbix/externalscripts/counters.ps1'
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
Invoke-Command -Session $session -FilePath $attrPathScript

Remove-PSSession $session
