$computers = @('pasvad01','pasvad02','pavfs01','pasvca01','pasvmail01')

ForEach ($computer in $computers) {

    $computer
    $error.clear()

    $ReturnValue = Invoke-Command -ComputerName $computer -ScriptBlock {

       $old = '<ca_verification>yes'
       $new = '<ca_verification>no'

       $return = (Get-Content 'C:\Program Files (x86)\ossec-agent\ossec.conf' -Raw).Replace($old,$new) | Set-Content 'C:\Program Files (x86)\ossec-agent\ossec.conf' 

       Restart-Service 'Wazuh'
   
    }
    if ($error.Count -gt 0) { throw $error[0] }
}
