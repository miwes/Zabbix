<#
.SYNOPSIS
	Install Wazuh Agent MSI Remote 
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
    ,[Parameter(Mandatory=$False)] [Alias("FileMSI")] [string]$attrFileMSI = '\\server\c$\ac\wazuh\wazuh-agent-4.4.1-1.msi'
    ,[Parameter(Mandatory=$False)] [Alias("WazuhServer")] [string]$attrWazuhServer = 'x.x.x.x'
	
	
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
        $version = Invoke-Command -ComputerName $attrComputer -Authentication Kerberos -ScriptBlock { (Get-Package -Name "Wazuh*").Version} -ErrorAction Stop
        Return $version
    } Catch {
        Return -1
    }
}

Function Install-WazuhAgent () {
    [CmdletBinding()] Param  (
        [Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrServername
        ,[Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrWazuhServer
        ,[Parameter(Mandatory = $true,valueFromPipeline=$true)] [string]$attrFileMSI
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

    $localPathMSI = 'C:\temp\' + $msiFile

    $arguments = "/i $localPathMSI /q WAZUH_REGISTRATION_SERVER='$attrWazuhServer' "
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

add-Log -attrText "[Info]; Check Wazuh agent on $attrServername"
$isWazuhAgent = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Get-Package -Name "Wazuh*" -ErrorAction SilentlyContinue}
If ($isWazuhAgent) {

    add-Log -attrText "[Info]; Get version installed Wazuh agent"
    [string]$InstalledVersion = Get-InstalledVersion -attrComputer $attrServername
    If ($InstalledVersion -eq -1) {
        add-Log -attrText "[Error]; Cannot get version installed Wazuh agent; $($Error[0])"
        add-Log -attrText "[Info]; End"
        Exit
    }

    $InstalledVersion = $InstalledVersion.Trim()

    If ($InstalledVersion -ne $MSIVersion) {
        <#
        # remove MSI agent Wazuh
        add-Log -attrText "[Info]; Installed version not eque MSI version ($MSIVersion -> $InstalledVersion)"
        add-Log -attrText "[Info]; Uninstall Wazuh agent on $attrServername ($InstalledVersion)"
        Try {
            $remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Get-Package -Name "Wazuh*" |  Uninstall-Package -Force }
        } Catch {
            add-Log -attrText "[Error]; Cannot uninstall Wazuh agent on $attrServername ($InstalledVersion); $($Error[0])"
            add-Log -attrText "[Info]; End"
            Exit
        }#>

        # install MSI agent Wazuh
        add-Log -attrText "[Info]; Install Wazuh agent on $attrServername ($MSIVersion)"
        $installAgent = Install-WazuhAgent -attrServername $attrServername -attrWazuhServer $attrWazuhServer -attrFileMSI $attrFileMSI
        If ($installAgent -ne 0) {
            add-Log -attrText "[Error]; Error when installed Wazuh agent on $attrServername ($MSIVersion); Error code $installAgent"
            Exit
        }
    } Else {
        add-Log -attrText "[Info]; Wazuh agent is already installed - $InstalledVersion"
    }
} Else {

    # install MSI agent Wazuh
    add-Log -attrText "[Info]; Install Wazuh agent on $attrServername ($MSIVersion)"
    $installAgent = Install-WazuhAgent -attrServername $attrServername -attrWazuhServer $attrWazuhServer -attrFileMSI $attrFileMSI
    If ($installAgent -ne 0) {
        add-Log -attrText "[Error]; Error when installed Wazuh agent on $attrServername ($MSIVersion); Error code $installAgent"
        Exit
    }

}

add-log -attrText "[Info]; Start Wazuh agent"
$remoteCommand = Invoke-Command -ComputerName $attrServername -Authentication Kerberos -ScriptBlock {Start-Service 'Wazuh'}
add-Log -attrText "[Info]; End"