<#                                          
    .SYNOPSIS  


    .NOTES

        State :  
            0 = SW_DEVICE_STATE_ACTIVE
            1 = SW_DEVICE_STATE_NON_ACTIVE,
            2 = SW_DEVICE_STATE_NOT_LICENSED,
            3 = SW_DEVICE_STATE_DISABLED,
            4 = SW_DEVICE_STATE_CLOSING

        Nodetype :
            0 = SW_HA_NODE_TYPE_UNDEFINE
            1 = SW_HA_NODE_TYPE_SYNC
            2 = SW_HA_NODE_TYPE_ASYN
            4 = SW_HA_NODE_TYPE_HEARTBEAT
            8 = SW_HA_NODE_TYPE_WITNESS

        SyncStatus :
            0 = SW_HA_SYNC_STATUS_UNDEFINED
            1 = SW_HA_SYNC_STATUS_SYNC
            2 = SW_HA_SYNC_STATUS_IN_PROGRESS
            3 = SW_HA_SYNC_STATUS_NOT_SYNC



#>

#Requires –Version 5.1

[CmdletBinding()] Param(
    [Parameter(Mandatory=$False)] [Alias("StarWindNode")] [string]$attrStarWindNode = '10.6.201.205'
    ,[Parameter(Mandatory=$False)] [Alias("StarWindUsername")] [string]$attrStarWindUsername = 'root'
    ,[Parameter(Mandatory=$False)] [Alias("StarWindPasswd")] [string]$attrStarWindPasswd = 'starwind'
)

[System.Threading.Thread]::CurrentThread.CurrentCulture = "en-US"
$Error.Clear()

Add-Type -TypeDefinition "public enum SwPerfCounterType { CpuAndRam = 0, Bandwidth, Iops }";
Add-Type -TypeDefinition "public enum SwPerfTimeInterval { LastHour = 0, LastDay }";

Try {
    $StarWindX = New-Object -ComObject StarWindX.StarWindX;
} Catch {
    Write-Verbose "[Error]; Cannot create com object StarWindX.StarWindX; $($Error[0])"
    Exit
}
$Server = $StarWindX.CreateServer($attrStarWindNode, 3261);
$Server.AuthentificationInfo.Login = $attrStarWindUsername;
$Server.AuthentificationInfo.Password = $attrStarWindPasswd;
$Server.AuthentificationInfo.IsChap = $False;

Try {
    $Server.Connect()
} Catch {
    Write-Verbose "[Error]; Cannot connect to $attrStarWindNode; $($Error[0])"
    Exit
}

$Devices = $Server.Devices| Select-Object Name, Size, State, NodeType, SyncStatus
$Devices | ConvertTo-Json

$Server.Disconnect()