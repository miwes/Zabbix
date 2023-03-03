$AvailableMemory = (Get-Counter '\Memory\Available Bytes').CounterSamples.CookedValue
$CPU = (Get-Counter '\Processor Information(_Total)\% Processor Time').CounterSamples.CookedValue

$void = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
$VBObject=[Microsoft.VisualBasic.Devices.ComputerInfo]::new()
$SystemMemory=$VBObject.TotalPhysicalMemory

$MemoryUsage = ($AvailableMemory*100)/$SystemMemory

$QLength = (Get-Counter '\System\Processor Queue Length').CounterSamples.CookedValue


$JSON  = '{"performance":{'
$JSON += '"memory": "' + $MemoryUsage + '",'
$JSON += '"cpu": "' + $CPU + '",'
$JSON += '"queueLength" : "' + $QLength + '"'
$JSON += '}}'

$JSON
