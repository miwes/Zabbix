[CmdletBinding()]
Param (
    [string]$ZURL       = 'https://zabbix.aclab.local/zabbix'
    ,[string]$ZUsername = ''
    ,[string]$ZPassword = ''
    ,[string]$Groupname = 'Windows servers'
    ,[string]$SURL      = "http://pasportnew.aclab.local/infra" 
    ,[string]$SUsername = ''
    ,[string]$SPassword = ''
    ,[string]$SRequest  = 'Po??adavek na VM'
    ,[string]$SRequestURL = 'http://pasport.aclab.local/infra/Lists/Poadavky/DispForm.aspx?ID'
)

Set-StrictMode –Version Latest
[System.Threading.Thread]::CurrentThread.CurrentCulture = "en-US"

Function Get-Logon () {
    Param (
        [Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$Username
        ,[Parameter(Mandatory=$true)] [string]$Password
    )

    $params = @{
        body =  @{
            "jsonrpc"= "2.0"
            "method"= "user.login"
            "params"= @{
                "user"= $Username
                "password"= $Password
            }
            "id"= 1
            "auth"= $null
        } | ConvertTo-Json
        uri = "$URL/api_jsonrpc.php"
        headers = @{"Content-Type" = "application/json"}
        method = "Post"
    }
    
    Try {
        $result = Invoke-WebRequest @params -SkipCertificateCheck
        $auth = ($result.Content | ConvertFrom-Json).result
        Return $auth
    } Catch {
        Return $null
    }
}

Function Get-HostsInGroup () {
    Param (
        [Parameter(Mandatory=$true)] [string]$Auth
        ,[Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$GroupName
    )
    $params = @{
        body = @{
            "jsonrpc"= "2.0"
            "method"= "hostgroup.get"
            "params"= @{
                output = "extend"
                selectHosts  = 'extend'
                filter = @{
                    name = $GroupName
                }
            }
            auth = $Auth
            id = 2
        } | ConvertTo-Json
        uri = "$URL/api_jsonrpc.php"
        headers = @{"Content-Type" = "application/json"}
        method = "Post"
    }
    
    $result = Invoke-WebRequest @params -SkipCertificateCheck
    $result = $result.Content | convertfrom-json
    Return $result.result.hosts
}

Function Get-IDRequest () {
    Param (
        [Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$Request
        ,[Parameter(Mandatory=$true)] [object]$Credent
    )
    Try {
        [xml]$xmlItems = Invoke-WebRequest -Uri "$URL/_api/web/lists/getbytitle('požadavky')/contenttypes" -Credential $credent -AllowUnencryptedAuthentication -ContentType "application/json;charset=utf-8" 
        [string]$sIDRequest = $xmlItems.feed.entry.content.properties | Where-Object {$_.Name -eq $Request } | Select-Object -ExpandProperty StringID
        Return $sIDRequest
    } Catch {
        Return $null
    }

}

Function Get-SHPVMId () {
    Param (
        [Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$VMName
        ,[Parameter(Mandatory=$true)] [string]$IDRequest
        ,[Parameter(Mandatory=$true)] [object]$Credent
    )
    $query =("<View><Query><Where><And><Eq><FieldRef Name='ContentTypeId' /><Value Type='Text'>$IDRequest</Value></Eq><Eq><FieldRef Name='Jm_x00e9_no_x0020_VM' /><Value Type='Text'>$VMName</Value></Eq></And></Where></Query></View>")
    $data = "{ ""query"" :{""__metadata"": { ""type"": ""SP.CamlQuery"" }, ""ViewXml"": ""$query""}}"  

    $response = Invoke-RestMethod -Method post -URI "$URL/_api/contextinfo" -Credential $credent -AllowUnencryptedAuthentication
    $Digest = $response.getcontextwebinformation.FormDigestValue
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("If-Match", "*")
    $headers.Add("X-HTTP-Method","POST")
    $Headers.Add("Content-Type","application/json;odata=verbose")
    $Headers.Add("X-RequestDigest",$Digest)

    Try {
        $xmlData = Invoke-RestMethod  -Uri "$URL/_api/web/lists/getbytitle('požadavky')/GetItems" -Headers $headers -Body $data -Credential $credent -Method POST -AllowUnencryptedAuthentication 
        # $xmlData = $output
         $idReturn = $xmlData.content.properties
         Return $idReturn
    } Catch {
        Write-Warning $Error[0]
        Return $null
    }
}

Function Get-SHPUser () {
    Param (
        [Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$UserID
        ,[Parameter(Mandatory=$true)] [object]$Credent
    )
    Try {
        $output = Invoke-RestMethod  -Uri "$URL/_api/web/GetUserByID($UserID)" -Credential $credent -Method GET -ContentType "application/json;charset=utf-8"  -AllowUnencryptedAuthentication 
        [xml]$xmlData = $output
        Return $xmlData.entry.content.properties
    } Catch {
        Return $null
    }
}

Function Get-ItemByID () {
    Param (
        [Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$ID
        ,[Parameter(Mandatory=$true)] [object]$List
        ,[Parameter(Mandatory=$true)] [object]$Credent
    )
    Try {
        $output = Invoke-RestMethod -Uri "$URL/_api/web/lists/getbytitle('$List')/items($ID)" -Credential $credent -ContentType "application/json;charset=utf-8"  -AllowUnencryptedAuthentication
        [xml]$xmlData = $output
        Return $xmlData.entry.content.properties
    } Catch {
        Write-Host $error[0]
        Return $null
    }
}

Function Set-HostInventory () {
    Param (
        [Parameter(Mandatory=$true)] [string]$Auth
        ,[Parameter(Mandatory=$true)] [string]$URL
        ,[Parameter(Mandatory=$true)] [string]$HostID
        ,[Parameter(Mandatory=$true)] $Property
    )

    $params = @{
        body = @{
            "jsonrpc"= "2.0"
            "method"= "host.update"
            "params"= @{
                hostid = [int]$hostID
                "inventory_mode" = 1
                "inventory" = 
                    $Property
            }
            auth = $Auth
            id = 2
        } | ConvertTo-Json
        uri = "$URL/api_jsonrpc.php"
        headers = @{'Content-Type' = 'application/json'}
        method = "Post"
    }
    $result = Invoke-WebRequest @params -SkipCertificateCheck
}

function Remove-Diacritics {
    param ([String]$src = [String]::Empty)
      $normalized = $src.Normalize( [Text.NormalizationForm]::FormD )
      $sb = new-object Text.StringBuilder
      $normalized.ToCharArray() | % { 
        if( [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
          [void]$sb.Append($_)
        }
      }
      $sb.ToString()
    }

Write-Verbose "Connecting to SHP - $SURL"
$sp = ConvertTo-SecureString $SPassword –asplaintext –Force
$credent = New-Object System.Management.Automation.PSCredential($SUsername,$sp)
$sRequestID = Get-IDRequest -URL $SURL -Request $SRequest -Credent $credent
If (-not $sRequestID) {    
    Write-Warning "Cannot logon to Sharepoint - $Error[0]"
    Exit
}

Write-Verbose "Connecting to Zabbix - $ZURL"
$oAuth = Get-Logon -URL $ZURL -Username $ZUsername -Password $ZPassword
If (-not $oAuth) {
    Write-Warning "Cannot logon to Zabbix - $Error[0]"
    Exit
}
$oHosts = Get-HostsInGroup -Auth $oAuth -URL $ZURL -GroupName $Groupname

ForEach ($oHost in $oHosts) {
    $VMId = Get-SHPVMId -URL $SURL -Credent $credent -IDRequest $sRequestID -VMName $oHost.name

    If (-not $VMId) {
        Write-Warning "Cannot find $($oHost.name)"
        Continue
    }
    If ($VMId.LANId.innertext) {
        $LAN = ''
        $LAN = (Get-ItemByID -URL $SURL -Credent $Credent -ID $VMId.LANId.innertext -List 'LAN').Title
    }
    If ($VMId.VlastnikVMId.innertext) {
        $oOwner = Get-SHPUser -URL $SURL -Credent $Credent -UserID $VMId.VlastnikVMId.innertext
    }
    If ($VMId.Technick_x00fd__x0020_garantId.innertext) {
        $oTechnicalContact = ''
        $oTechnicalContact = Get-SHPUser -URL $SURL -Credent $Credent -UserID $VMId.Technick_x00fd__x0020_garantId.innertext
    }

    $SetProperty = @{
        'notes' = Remove-Diacritics($VMID.ucel)
        'poc_1_email' = $oOwner.Email
        'poc_1_name' = Remove-Diacritics($oOwner.Title)
        'poc_2_email' = $oTechnicalContact.Email
        'poc_2_name' = Remove-Diacritics($oTechnicalContact.Title)
        'url_a' = "$SRequestURL=$($VMId.id[0].innertext)"
        'host_networks' = Remove-Diacritics($LAN)
        'tag' = $VMId.Perfix_x0020_jm_x00e9_na
    }
    Write-Verbose "Update $($oHost.name)"
    Set-HostInventory -Auth $oAuth -URL $ZURL -HostID $oHost.hostid -Property $SetProperty
}



