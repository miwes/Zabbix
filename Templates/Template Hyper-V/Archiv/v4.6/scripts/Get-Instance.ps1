Param(
	[string]$Counter
)
('{"data":[' + (Get-Counter -Counter $Counter | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty InstanceName | ForEach {'{"{#INSTANCE}":"' + $_ + '"},'}) + ']}') -Replace ',]}', ']}'