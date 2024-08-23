# Rozdeleni PFX na 2 casti
```
openssl pkcs12 -in domain.pfx -clcerts -nokeys -out domain.cer
openssl pkcs12 -in domain.pfx -nocerts -nodes  -out domain.key 
```
