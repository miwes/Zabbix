[CmdletBinding()] Param(
    [string]$VM
    ,[string]$WhatReturn
    ,[string]$URL     = "http://pasportnew.aclab.local/infra" #_api/web/lists/getbytitle('požadavky')/contenttypes
    ,[string]$Username = 'aclab.local\zabbixwebmonitor'
    ,[string]$Password = ''
    ,[string]$Request = 'Po??adavek na VM'
)

$sp = ConvertTo-SecureString $Password –asplaintext –Force
$credent = New-Object System.Management.Automation.PSCredential($Username,$sp)

[xml]$xmlItems = Invoke-WebRequest -Uri "$URL/_api/web/lists/getbytitle('požadavky')/contenttypes" -Credential $credent -AllowUnencryptedAuthentication -ContentType "application/json;charset=utf-8" 
[string]$sIDRequest = $xmlItems.feed.entry.content.properties | Where-Object {$_.Name -eq $Request } | Select-Object -ExpandProperty StringID

$query =("<View><Query><Where><And><Eq><FieldRef Name='ContentTypeId' /><Value Type='Text'>$sIDRequest</Value></Eq><Contains><FieldRef Name='AktivniVM' /><Value Type='Text'>$VM</Value></Contains></And></Where></Query></View>")
$data = "{ ""query"" :{""__metadata"": { ""type"": ""SP.CamlQuery"" }, ""ViewXml"": ""$query""}}"  

$response = Invoke-RestMethod -Method post -URI "$URL/_api/contextinfo" -Credential $credent -AllowUnencryptedAuthentication
$Digest = $response.getcontextwebinformation.FormDigestValue
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("If-Match", "*")
$headers.Add("X-HTTP-Method","POST")
$Headers.Add("accept","application/atom+xml")
$Headers.Add("Content-Type","application/json;odata=verbose")
$Headers.Add("X-RequestDigest",$Digest)

Try {
    [xml]$xmlVM = Invoke-WebRequest  -Uri "$URL/_api/web/lists/getbytitle('požadavky')/GetItems" -Headers $headers -Body $data -Credential $credent -Method POST -AllowUnencryptedAuthentication # -ContentType "application/json;odata=verbose"
    $idReturn = $xmlVM.feed.entry.content.properties.$WhatReturn.innertext
} Catch {
    Write-Warning $Error[0]
    exit
}

If ($idReturn) {
    [xml]$xmlData = Invoke-WebRequest  -Uri "$URL/_api/web/GetUserByID($idReturn)" -Headers $headers -Credential $credent -Method GET -AllowUnencryptedAuthentication # -ContentType "application/json;odata=verbose"
    $xmlData.entry.content.properties
}
