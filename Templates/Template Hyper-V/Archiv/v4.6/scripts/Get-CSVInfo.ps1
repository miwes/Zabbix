[cmdletbinding()]
Param(
    [string] $CSVName
)


$objs= @()
If ($CSVName -eq '') {
    $csvs = Get-ClusterSharedVolume 
    foreach ( $csv in $csvs ) 
    { 
       $csvinfos = $csv | select-object -Property Name -ExpandProperty SharedVolumeInfo 
       foreach ( $csvinfo in $csvinfos ) 
       { 
	    $obj = New-Object PSObject -Property @{
		    "{#NAME}" = $csv.Name 
    #		"{#FREESPACE}" = $csvinfo.Partition.FreeSpace
	    }
	    $objs += $obj
       } 
    } 
    $JSON = ConvertTo-Json $objs
    Write-Host '{"data":' ; $JSON ; Write-Host '}'
}
Else {
    $CSV = Get-ClusterSharedVolume -Name $CSVName | select-object -Property Name -ExpandProperty SharedVolumeInfo 
    $CSV.Partition.FreeSpace
}