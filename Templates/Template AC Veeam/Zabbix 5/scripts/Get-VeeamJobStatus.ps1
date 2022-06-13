<#
.SYNOPSIS
    Read information about jobs
.DESCRIPTION
.NOTES

.LINK
.EXAMPLE

#>

<# TODO

#>

[CmdletBinding()]Param (
     [Parameter(Mandatory=$False)] [Alias("Discovery")]   [switch]$attrDiscovery
    ,[Parameter(Mandatory=$False)] [Alias("JobID")]     [string]$attrJobID
    ,[Parameter(Mandatory=$False)] [Alias("Information")] [ValidateSet('Status','LastRun')] [string]$attrInformation = 'Status'
)


# inicialization
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
        #$jobs = Get-VBRJob
        $jobs = [Veeam.Backup.Core.CBackupJob]::GetAll()
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
ElseIf ($attrJobID)
{
    # find last session
    $session = [Veeam.Backup.Core.CBackupJob]::FindLastSession($attrJobID)
    Switch ($attrInformation)
    {
        'Status'   
        { 
            Try 
            {
                # only read when job not running
                If ($session.State -eq 'Stopped') 
                {
                    $returnJSON = $session.result.ToString().Trim()
                }
                Else
                {
                    $returnJSON = 'Running'
                }
            }
            Catch
            {
                $returnJSON = 'Not readable'
            }
        }
        'LastRun'  
        { 
            Try 
            {
                $returnJSON = $session.EndTime.ToString().Trim()
            }
            Catch
            {
                $returnJSON = 'Not readable'
            }
        }

    }
}

$returnJSON
