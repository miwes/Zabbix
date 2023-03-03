# Monitoring Windows serveru bez agenta

## Na Linux serveru je nutne mit doinstalovane
PWSH
gss-ntlmssp (apt install gss-ntlmssp)

##Pozadavky
- pro ziskani dat je vyuzit Powershell
- ucet pro monitoring musí mít admin práva na koncových bodech, pokud chceme monitorovat jiné než performance věci
- pro monitoring vykonnosti stačí práva "Remote management users"

## Zasifrovani pristupove hesla
Pro ziskavani dat je vyuzit AD ucet, heslo je zasifrovano pomoci AES a klic je ulozen v databazi Zabbixu

#### Postup pro vytvoreni hesla
```
$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | Out-File .\aes.key

"Heslo12345" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -key $key | Out-File .\password.txt
```




