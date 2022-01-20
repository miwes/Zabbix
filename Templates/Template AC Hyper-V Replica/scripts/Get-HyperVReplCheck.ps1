<#
.SYNOPSIS
    Kontrola replikace Hyper-V
.DESCRIPTION
    Pro spravnou funkci je nutne mit na Hyper-V vytvoreny PSSession ZabbixMonitoring s pravy get-vm, select-object, get-vmsnapshot
.NOTES
.LINK
.EXAMPLE
.PARAMETER foo
.PARAMETER bar
#>

<# TODO

#>

[CmdletBinding()]Param (
    [Parameter(Mandatory=$False)] [Alias("ClusterName")] [string]$attrClusterName = 'cluster'
    ,[Parameter(Mandatory=$False)] [Alias("ListReplicas")] [switch]$attrListReplicas
    ,[Parameter(Mandatory=$False)] [Alias("VMReplicaName")] [string]$attrVMReplicaName
    ,[Parameter(Mandatory=$False)] [Alias("GetSnapshotDate")] [switch]$attrGetSnapshotDate
)

# inicialization
Set-StrictMode -Version latest
$global:ErrorActionPreference = 'Stop'
$Error.Clear()

# check input parameteres
If (!$attrListReplicas -and ($attrVMReplicaName -eq ''))
{
    Write-Warning 'You must specify VMReplicaName'
    Exit
}


# get Nodes
$nodes = Get-ClusterNode -Cluster $attrClusterName


# get all replicas on cluster
If ($attrListReplicas) 
{
    # create array
    $vmReplica = @()

    ForEach ($node In $nodes) 
    {
        Write-Verbose "Get all VM from $node"
        # get all replica VM
        $vmReplica += (Invoke-Command -ComputerName $node -ConfigurationName ZabbixMonitoring -ScriptBlock {Get-VM | Select-Object Name} | Where {$_.name -like '*_replica'})
    }

    # format output in JSON for Zabbix
    $dataJson = '{"data": ['

    ForEach ($replica In $vmReplica)
    {
        $dataJson += '{"{#REPLICANAME}":"'+ $($replica.Name.Trim()) + '"},'
    }
    # remove last ,
    $dataJson = $dataJson -replace ".$"

    $dataJson += ']}'

    # list data
    $dataJson
    
}
# get  replicas state for special VM
Else 
{
    # convert replica to VM
    $vmOriginalName = $attrVMReplicaName.Replace('_replica','')

    If (!$attrGetSnapshotDate)
    {

        # create array
        $vmOriginal = @()
        $vmReplica = @()

        ForEach ($node In $nodes) 
        {
            $WarningPreference = 'SilentlyContinue'
            Write-Verbose "Get all VM from $node"
            # get all VM
            $vmAll = (Invoke-Command -ComputerName $node -ConfigurationName ZabbixMonitoring -ScriptBlock {Get-VM | Select-Object Name,Path})
            $vmOriginal += $vmAll| Where-Object {$_.Name -eq $vmOriginalName}
    
            # get all replica VM
            $vmReplica += $vmAll| Where-Object {$_.Name -eq $attrVMReplicaName}
        }

        If (!$vmReplica -or !$vmOriginal) 
        {
            Write-Host 'Cannot find VM'
        }

        $storageReplica = $vmReplica.path.split('\')[2]

        # original VM storage
        $storageOriginal =  $vmOriginal.path.split('\')[2]

        If ($storageReplica[3] -eq $storageOriginal[3]) 
        {
            # it's not ok
            Write-Host 1
        }
        Else
        {
            # it's ok
            Write-Host 0
        }
    } 
    Else 
    {
        # create array
        $vmReplicaSnapShotTime= @()

        ForEach ($node In $nodes) 
        {
            $WarningPreference = 'SilentlyContinue'
            Write-Verbose "Get all VM from $node"
            # get all VM
            $vmReplicaSnapShotTime += (Invoke-Command -ComputerName $node -ConfigurationName ZabbixMonitoring -ScriptBlock {$attrVMReplicaName = $args[0];Get-VMSnapshot -VMName $attrVMReplicaName -ErrorAction SilentlyContinue| Select-Object CreationTime} -ArgumentList $attrVMReplicaName )
        }

        $DateTime = $vmReplicaSnapShotTime.CreationTime
        Write-Host  ([DateTimeOffset]$DateTime).ToUnixTimeSeconds()
    }
}