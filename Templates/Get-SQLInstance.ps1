#verze 1.1

Param(

    $default = 'false'
)

$objSQLInstance = Get-Service |? {$_.DisplayName -like 'SQL Server (*'} | Select -ExpandProperty DisplayName
$Return = ''

ForEach ($objService In $objSQLInstance) {
    $NameInstance = $objService.Replace('SQL Server (','').Replace(')','')
    If ($default -eq 'true')
    {
        If ($NameInstance -eq 'MSSQLSERVER') {
            $Return = '{"{#SQLINSTANCE}": "SQLServer"}}'
        }
    } Else {
        If ($NameInstance -ne 'MSSQLSERVER') {
            $Return += '{"{#SQLINSTANCE}": "'+$NameInstance+'"},'
        }
    }
}
If ($Return) {
    $JSON = $Return  -replace ".{1}$"
    Write-Host '{"data":[' ; $JSON ; Write-Host ']}'
} Else {
    Write-Host '{"data":[{"{#SQLINSTANCE}":"NULL"}]}'
}