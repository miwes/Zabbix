<#
.SYNOPSIS
	Install Zabbix Agent MSI Remote - urceno pro verzi Zabbix agenta v1
.DESCRIPTION
	Version :
		1.0 - Initial realease
		1.1	- Change PSExec to Invoke-Command
.NOTES
.LINK
.EXAMPLE
.PARAMETER attrServername
#>

[CmdletBinding()]Param (
    [Parameter(Mandatory=$True)] [Alias("ServerName")] [string]$attrServername
    ,[Parameter(Mandatory=$False)] [Alias("FileMSI")] [string]$attrFileMSI = '\\server\Zabbix\Agent\zabbix_agent-6.0.17-windows-amd64-openssl.msi'
    ,[Parameter(Mandatory=$False)] [Alias("ZabbixServer")] [string]$attrZabbixServer = 'x.x.x.x'
    ,[Parameter(Mandatory=$False)] [Alias("ZabbixConfigFiles")] [string]$attrZabbixConfigFiles = '\\server\Zabbix\Config\'
	
	# add as suffix on hostname in zabbix agent config file
	,[Parameter(Mandatory=$False)] [Alias("DomainName")] [string]$attrDomainName = '.aclab.local'
)

Set-StrictMode -Version latest
$global:ErrorActionPreference = 'Stop'
$Error.Clear()

#region function
Function add-Log () {
    <#
    .SYNOPSIS
    Add data to log file

    #>

    [CmdletBinding()] Param  (
         #[Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrFile
        [Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrText
        ,[Parameter(Mandatory = $false,valueFromPipeline=$true)] [switch]$attrVerbose = $true
    )

    $TimeStamp = Get-Date
    <#
    Try {
        "$TimeStamp;$attrText" | Out-File -FilePath $attrFile -Append -ErrorAction Stop
    } Catch {
        Return $False
    }#>
    If ($attrVerbose) {
        Write-Verbose $($attrText).ToString()
    }
}

Function Get-MSIVersion () {
    
    [CmdletBinding()] Param  (
        [Parameter(Mandatory = $true,valueFromPipeline=$true)] [IO.FileInfo]$attrMSIPath
    )

    try {
        $windowsInstaller = New-Object -com WindowsInstaller.Installer
        $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $windowsInstaller, @($attrMSIPath.FullName, 0))
 
        $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $database, ($q))
 
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)
        $record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null )
        $version = $record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $record, 1 )
 
        Return $version
    } catch {
        Return -1
    }
}

Function Get-InstalledVersion () {
    [CmdletBinding()] Param  (
        [Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrComputer
    )

    Try {
        $version = Invoke-Command -ComputerName $attrComputer -Authentication Kerberos -ScriptBlock { (Get-Package -Name "Zabbix*").Version} -ErrorAction Stop
        Return $version
    } Catch {
        Return -1
    }
}

Function Install-ZabbixAgent () {
    [CmdletBinding()] Param  (
        [Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrServername
        ,[Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrZabbixServer
        ,[Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrFileMSI
		,[Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrDomainName
    )
    
    # copy MSI to local
    Try {
        $msiFile = $attrFileMSI.Split('\')[-1]
        $localTemp = '\\' + $attrServername + '\c$\temp\'
        $localMSI =  $localTemp +$msiFile
        If (! (Test-Path $localTemp)) {
            New-Item -Path $localTemp -ItemType Directory | Out-Null
        }
        Copy-Item $attrFileMSI $localMSI
    } Catch {
        Write-Host "[Error]: Cannot copy MSI to server : $($Error[0])"
        Return -1
    }

    $hostname = "$attrServername".ToUpper() + $attrDomainName
    $arguments = "/i $localMSI /l*v c:\zabbix_agent_install_log.txt /qn SERVER=$attrZabbixServer SERVERACTIVE=$attrZabbixServer HOSTNAME=$hostname"
    $install = Invoke-Command -ComputerName $attrServername -ScriptBlock {
        param ($arguments)
        Try {
            $ExitCode = (Start-Process msiexec.exe -ArgumentList $arguments -Wait -PassThru).ExitCode
            Return $ExitCode
        } Catch {
            Return -1
        }
       } -ArgumentList $arguments -AsJob
    Wait-Job -Job $install | Out-Null
    $ReturnValue = Receive-Job -Job $install

    # delete MSI
    Remove-Item -Path $localMSI

    Return $ReturnValue
}
#end region


add-Log -attrText "[Info]; Start"

add-Log -attrText "[Info]; Get version of MSI file - $attrFileMSI"
[string]$MSIVersion = (Get-MSIVersion -attrMSIPath $attrFileMSI)
If ($MSIVersion -eq -1) {
    add-Log -attrText "[Error]; Cannot get version MSI; $($Error[0])"
    add-Log -attrText "[Info]; End"
    Exit
}
$MSIVersion = $MSIVersion.Trim()

add-Log -attrText "[Info]; Check Zabbix agent on $attrServername"
$isZabbixAgent = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Get-Package -Name "Zabbix*" -ErrorAction SilentlyContinue}
If ($isZabbixAgent) {

    add-Log -attrText "[Info]; Get version installed Zabbix agent"
    [string]$InstalledVersion = Get-InstalledVersion -attrComputer $attrServername
    If ($InstalledVersion -eq -1) {
        add-Log -attrText "[Error]; Cannot get version installed Zabbix agent; $($Error[0])"
        add-Log -attrText "[Info]; End"
        Exit
    }

    $InstalledVersion = $InstalledVersion.Trim()

    If ($InstalledVersion -ne $MSIVersion) {
        # remove MSI agent Zabbix
        add-Log -attrText "[Info]; Installed version not eque MSI version ($MSIVersion -> $InstalledVersion)"
        add-Log -attrText "[Info]; Uninstall Zabbix agent on $attrServername ($InstalledVersion)"
        Try {
            $remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Get-Package -Name "Zabbix*" |  Uninstall-Package -Force }
        } Catch {
            add-Log -attrText "[Error]; Cannot uninstall Zabbix agent on $attrServername ($InstalledVersion); $($Error[0])"
            add-Log -attrText "[Info]; End"
            Exit
        }

        # install MSI agent Zabbix
        add-Log -attrText "[Info]; Install Zabbix agent on $attrServername ($MSIVersion)"
        $installAgent = Install-ZabbixAgent -attrServername $attrServername -attrZabbixServer $attrZabbixServer -attrFileMSI $attrFileMSI -attrDomainName $attrDomainName
        If ($installAgent -ne 0) {
            add-Log -attrText "[Error]; Error when installed Zabbix agent on $attrServername ($MSIVersion); Error code $installAgent"
            Exit
        }
    } Else {
        add-Log -attrText "[Info]; Zabbix agent is already installed - $InstalledVersion"
    }
} Else {

    # install MSI agent Zabbix
    add-Log -attrText "[Info]; Install Zabbix agent on $attrServername ($MSIVersion)"
    $installAgent = Install-ZabbixAgent -attrServername $attrServername -attrZabbixServer $attrZabbixServer -attrFileMSI $attrFileMSI -attrDomainName $attrDomainName
    If ($installAgent -ne 0) {
        add-Log -attrText "[Error]; Error when installed Zabbix agent on $attrServername ($MSIVersion); Error code $installAgent"
        Exit
    }

  Write-Verbose "[Info]; Wait 20 sec"
  Start-Sleep -s 20
}



# update config files
add-Log -attrText "[Info]; Test path $attrZabbixConfigFiles"
If (Test-Path -Path $attrZabbixConfigFiles) {
    add-Log -attrText "[Info]; Copy config path $attrZabbixConfigFiles -> \\$($attrServername)\c$\Program Files\Zabbix Agent\zabbix_agentd.d\"
    Copy-Item -Path "$attrZabbixConfigFiles\*.*" -Destination "\\$($attrServername)\c$\Program Files\Zabbix Agent\zabbix_agentd.d\" -Force -Confirm:$False
    
    add-Log -attrText "[Info]; Restart Zabbix agent on $attrServername"
    $remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Restart-Service -Name "Zabbix Agent"}

    add-Log -attrText "[Info]; Wait 7 seconds and try start Zabbix agent on $attrServername"
    start-sleep -seconds 7    
    $remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Start-Service -Name "Zabbix Agent"}
} Else {
    add-Log -attrText "[Info]; Path $attrZabbixConfigFiles doesnt exist"
}

add-Log -attrText "[Info]; End"
