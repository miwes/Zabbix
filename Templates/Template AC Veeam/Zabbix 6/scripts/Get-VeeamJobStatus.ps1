<#
.SYNOPSIS
    Read information about jobs
    - History
        - 1.1 - return XML with all jobs information
.DESCRIPTION
.NOTES

.LINK
.EXAMPLE

#>

<# TODO

#>

[CmdletBinding()]Param (
     [Parameter(Mandatory=$False)] [Alias("Discovery")] [switch]$attrDiscovery
)


# inicialization
Set-StrictMode -Version latest
$global:ErrorActionPreference = 'Stop'
$Error.Clear()

    
#$VerbosePreference='Continue'
    
# load snappin
Write-Verbose "[info]; Load VeeamPSSnapin"
Try 
{
    $module = Import-Module Veeam.Backup.PowerShell -ErrorAction stop -Verbose:$false 3> $null 
} 
Catch 
{
    Write-Verbose "[info]; Cannot load VeeamPSSnapin;$($Error[0])"
    Exit
}

# return value
$returnJSON = ''

If ($attrDiscovery) 
{
    # discovery mode, list all backup job
    $returnJSON = '['

    # load jobs
    Write-Verbose "[info]; Get Veeam jobs"
    Try 
    {
        $jobs = Get-VBRJob -WarningAction Ignore
        #$jobs = [Veeam.Backup.Core.CBackupJob]::GetAll()
    } 
    Catch 
    {
        Write-Verbose "[info]; Cannot get Veeam jobs;$($Error[0])"
        Exit
    }


    ForEach($job In $jobs) 
    {
        $returnJSON += '{'
        $returnJSON += '"{#BACKUPJOBNAME}":"' + $job.Name + '",'
        $description = ($job.Description).Replace('\','\\')
        $description = $description -replace "`t|`n|`r",""
        $returnJSON += '"{#BACKUPJOBID}":"' + $job.id + '",'
        $returnJSON += '"{#BACKUPJOBDESCRIPTION}":"' + $description + '"'
        $returnJSON += '},'
    }
    
    # remove last ,
    $returnJSON = $returnJSON -replace ".$"
    $returnJSON += ']'
}
Else
{

    Try {
        $lastSession = (Get-VBRJob -WarningAction Ignore).findLastSession()
        $returnJSOn = ($lastSession | ConvertTo-Xml | select OuterXml).OuterXml 
    }
    Catch {
        Write-Verbose "[Error]; $($Error[0])"
    }
}

$returnJSON