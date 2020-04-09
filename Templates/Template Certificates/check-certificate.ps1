Param (
    [string]$URLs
    ,[int]$DaysToExpiration = 0
)

ForEach($URL in $URLs.Split(';')) {
    [System.Uri] $Url = New-Object System.Uri($URL)
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $req = [Net.HttpWebRequest]::Create($url)
    Try {
        $req.GetResponse().Dispose() | Out-Null
        Try {
            $expiredDate = $req.ServicePoint.Certificate.GetExpirationDateString()
            $Days = (New-TimeSpan -Start (Get-Date) -End $expiredDate).Days
            If ($DaysToExpiration -eq 1) {
                $Return =  $Days 
            } Else {
                $Return += '{"{#URL}":"' + $URL +'"},'
            }
        }
        Catch {Write-Error $Error[0]}
    }
    Catch {Write-Error $Error[0]}
}
If ($DaysToExpiration -ne 1) {
    $JSON = $Return  -replace ".{1}$"
    $Return =  '{"data":[' + $JSON + ']}'
}
$Return
