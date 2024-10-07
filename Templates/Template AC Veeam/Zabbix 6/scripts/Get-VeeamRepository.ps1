<#
.SYNOPSIS
    Read information about repository
.DESCRIPTION
.NOTES

.LINK
.EXAMPLE

#>

<# TODO

#>

[CmdletBinding()]Param (
     [Parameter(Mandatory=$False)] [Alias("Discovery")]     [switch]$attrDiscovery
    ,[Parameter(Mandatory=$False)] [Alias("RepositoryID")]  [string]$attrRepositoryID
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
    # discovery mode, list all repository
    $returnJSON = '['

    # load jobs
    Write-Verbose "[info]; Get Veeam repository"
    Try 
    {
        $repository =  Get-VBRBackupRepository
    } 
    Catch 
    {
        Write-Verbose "[info]; Cannot get Veeam repository;$($Error[0])"
        Exit
    }


    ForEach($repo In $repository) 
    {
        $returnJSON += '{'
        $name = ($repo.Name).Replace('\','\\')
        $returnJSON += '"{#REPOSITORYNAME}":"' + $name + '",'
        $description = ($repo.Description).Replace('\','\\')
        $returnJSON += '"{#REPOSITORYID}":"' + $repo.id + '",'
        $returnJSON += '"{#REPOSITORYDESCRIPTION}":"' + $description + '"'
        $returnJSON += '},'
    }
    
    # remove last ,
    $returnJSON = $returnJSON -replace ".$"
    $returnJSON += ']'
}
ElseIf ($attrRepositoryID)
{
    # get Veeam repository, have to use ID -> zabbix now allowed char \ in USERPARAMETER
    $repo = Get-VBRBackupRepository | Where-Object {$_.id -eq $attrRepositoryID}

    # get usage
    $repoUsage = $repo | Select-Object @{n='Name';e={$_.Name}},@{n='Type';e={$_.type}},  @{n='Path';e={$_.path}}, @{n='Size';e={$_.GetContainer().CachedTotalSpace.Inbytes}}, @{n='FreeSpace';e={$_.GetContainer().CachedFreeSpace.Inbytes}}

    $returnJSON = '['
    $returnJSON += '{'
    $returnJSON += '"REPOSITORYSIZE":"' + $repoUsage.Size + '",'
    $returnJSON += '"REPOSITORYFREESPACE":"' + $repoUsage.FreeSpace + '"'
    $returnJSON += '}'
    $returnJSON += ']'

}

$returnJSON
