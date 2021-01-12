<#
.SYNOPSIS
	Install Zabbix Agent MSI Remote
.DESCRIPTION
.NOTES
.LINK
.EXAMPLE
.PARAMETER attrServername
#>

[CmdletBinding()]Param (
    [Parameter(Mandatory=$True,Position=1)] [Alias("ServerName")] [string]$attrServername
    ,[Parameter(Mandatory=$False,Position=2)] [Alias("FileMSI")] [string]$attrFileMSI = '\\server\zabbix\Agent\zabbix_agent-5.0.4-windows-amd64-openssl.msi'
    ,[Parameter(Mandatory=$False,Position=3)] [Alias("ZabbixServer")] [string]$attrZabbixServer = 'zabbix'
    ,[Parameter(Mandatory=$False,Position=3)] [Alias("ZabbixConfigFiles")] [string]$attrZabbixConfigFiles = '\\server\zabbix\Config\'
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
    )

    $hostname = "$attrServername".ToUpper()
    $arguments = "\\$attrServername -d -s msiexec /i $attrFileMSI /l*v c:\zabbix_agent_install_log.txt /qn SERVER=$attrZabbixServer SERVERACTIVE=$attrZabbixServer HOSTNAME=$hostname"
    $remoteInstall = Start-Process .\PsExec64.exe -ArgumentList $arguments -Wait -PassThru
    $handle = $remoteInstall.Handle
    $remoteInstall.WaitForExit();
    $exitCode = $remoteInstall.ExitCode
    Return $exitCode
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
            $remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Get-Package -Name "Zabbix*" |  Uninstall-Package -Force}
        } Catch {
            add-Log -attrText "[Error]; Cannot uninstall Zabbix agent on $attrServername ($InstalledVersion); $($Error[0])"
            add-Log -attrText "[Info]; End"
            Exit
        }

        # install MSI agent Zabbix
        add-Log -attrText "[Info]; Install Zabbix agent on $attrServername ($MSIVersion)"
        $installAgent = Install-ZabbixAgent -attrServername $attrServername -attrZabbixServer $attrZabbixServer
        If ($installAgent -ne 0) {
            add-Log -attrText "[Error]; Error when installed Zabbix agent on $attrServername ($MSIVersion); Error code $installAgent"
        }
    } Else {
        add-Log -attrText "[Info]; Zabbix agent is already installed - $InstalledVersion"
    }
} Else {

    # install MSI agent Zabbix
    add-Log -attrText "[Info]; Install Zabbix agent on $attrServername ($MSIVersion)"
    $installAgent = Install-ZabbixAgent -attrServername $attrServername -attrZabbixServer $attrZabbixServer
    If ($installAgent -ne 0) {
        add-Log -attrText "[Error]; Error when installed Zabbix agent on $attrServername ($MSIVersion); Error code $installAgent"
    }
}

Write-Verbose "[Info]; Wait 20 sec"
Start-Sleep -s 20

# update config files
add-Log -attrText "[Info]; Test path $attrZabbixConfigFiles"
If (Test-Path -Path $attrZabbixConfigFiles) {
    add-Log -attrText "[Info]; Copy config path $attrZabbixConfigFiles"
    Copy-Item -Path "$attrZabbixConfigFiles\*.*" -Destination "\\$($attrServername)\c$\Program Files\Zabbix Agent\zabbix_agentd.conf.d\" -Force -Confirm:$False
    
    add-Log -attrText "[Info]; Restart Zabbix agent on $attrServername"
    $remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Restart-Service -Name "Zabbix Agent"}
} Else {
    add-Log -attrText "[Info]; Path $attrZabbixConfigFiles doesnt exist"
}

add-Log -attrText "[Info]; End"