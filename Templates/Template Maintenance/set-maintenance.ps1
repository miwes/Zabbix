Param (
    $hostname
)

If ((get-date).IsDaylightSavingTime() -eq $TRUE) {
    $From = [int][double]::Parse((Get-Date -UFormat %s))
    $To =  [int][double]::Parse((Get-Date -UFormat %s))+1800
} Else {
    $From = [int][double]::Parse((Get-Date -UFormat %s))-3600
    $To =  [int][double]::Parse((Get-Date -UFormat %s))-1800
}
$baseurl = 'https://zabbix.aclab.local/zabbix'
$MaintenanceName = "Manual maintenance $hostname"

$params = @{
    body =  @{
        "jsonrpc"= "2.0"
        "method"= "user.login"
        "params"= @{
            "user"= 'schedulertask'
            "password"= ''
        }
        "id"= 1
        "auth"= $null
    } | ConvertTo-Json
    uri = "$baseurl/api_jsonrpc.php"
    headers = @{"Content-Type" = "application/json"}
    method = "Post"
}

$result = Invoke-WebRequest @params -SkipCertificateCheck
$auth = ($result.Content | ConvertFrom-Json).result

$params.body = @{
    "jsonrpc"= "2.0"
    "method"= "host.get"
    "params"= @{
        output = "extend"
        filter = @{
            host = $hostname
        }
    }
    auth = $auth
    id = 2
} | ConvertTo-Json

$result = Invoke-WebRequest @params -SkipCertificateCheck
$result = $result.Content | convertfrom-json
$hostid = $result.result.hostid

# get maintenance
$params.body = @{
    "jsonrpc"= "2.0"
    "method"= "maintenance.get"
    "params"= @{

        hostids = @([int]$hostid)
    }
    auth = $auth
    id = 1
} | ConvertTo-Json  -Depth 100

$result = Invoke-WebRequest @params -SkipCertificateCheck
$result = $result.Content | convertfrom-json
$Update = $false
ForEach ($Maintenance in $result.result) {
    If ($Maintenance.name -eq $MaintenanceName) {
        $Update = $True
        $MaintenanceID = $Maintenance.maintenanceid
    }
}

If ($Update -eq $false) {
    $params.body = @{
        "jsonrpc"= "2.0"
        "method"= "maintenance.create"
        "params"= @{
            name = $MaintenanceName
            description = "AC"
            active_since = $From
            active_till = $to
            groupids = @()
            hostids = @([int]$hostid)
            timeperiods = @(
            @{
                timeperiod_type = 0
            })
        }
        auth = $auth
        id = 1
    } | ConvertTo-Json  -Depth 100
    $result = Invoke-WebRequest @params -SkipCertificateCheck
} Else {
    $params.body = @{
        "jsonrpc"= "2.0"
        "method"= "maintenance.update"
        "params"= @{
            maintenanceid = "$MaintenanceID"
            active_since = $From
            active_till = $to
            groupids = @()
            hostids = @([int]$hostid)
            timeperiods = @(
            @{
                timeperiod_type = 0
            })
        }
        auth = $auth
        id = 1
    } | ConvertTo-Json  -Depth 100
    $params.body
    $result = Invoke-WebRequest @params -SkipCertificateCheck
}

$params.body =  @{
        "jsonrpc"= "2.0"
        "method"= "user.logout"
        "id"= 1
        "params" = @()
        "auth" = $auth
} | ConvertTo-Json
$result = Invoke-WebRequest @params -SkipCertificateCheck
