<#
.SYNOPSIS
	Prida Zabbix host do Zabbix serveru
.DESCRIPTION
.NOTES
.LINK
.EXAMPLE
	./change-ZabbixConf.ps1 -verbose -attrComputers "server1","server2"
.PARAMETER attrHostCSV
	Musi obsahovat sloupce Host a IP
#>

[CmdletBinding()]Param (
     [Parameter(Mandatory=$False)]  [string]$attrURL = "https://zabbix/api_jsonrpc.php"
	,[Parameter(Mandatory=$False)]  [string]$attrZabbixUser = "ac.weis"
	,[Parameter(Mandatory=$False)]  [string]$attrHostCSV = "C:\Work\Zabbix\mpp.csv"
	,[Parameter(Mandatory=$true)] 	[string]$attrGroupID
	,[Parameter(Mandatory=$true)] 	[string]$attrProxyID
	,[Parameter(Mandatory=$true)] 	[string]$attrTemplateID
)

Function Get-LoginZabbix () {
    Param (
        [Parameter(Mandatory=$true)] [string]$attrZabbixServer
        ,[Parameter(Mandatory=$true)] [PSCredential]$attrCredentials
    )


    $params = @{
        body =  @{
            "jsonrpc"= "2.0"
            "method"= "user.login"
            "params"= @{
                "user"= $attrCredentials.UserName
                "password"= $attrCredentials.GetNetworkCredential().Password
            }
            "id"= 1
            "auth"= $null
        } | ConvertTo-Json
        uri = "$attrZabbixServer"
        headers = @{"Content-Type" = "application/json"}
        method = "Post"
    }
    
    Try {
        $result = Invoke-WebRequest @params 
        $auth = ($result.Content | ConvertFrom-Json).result
        If (-not $auth) {
            Write-Host ($result.Content | ConvertFrom-Json).error.data
            Return $null
        } Else {        
            Return $auth
        }
    } Catch {
        Write-Host $Error[0]
        Return $null
    }
}

Function Get-LogoutZabbix () {
    Param (
        [Parameter(Mandatory=$true)] [string]$attrZabbixServer
        ,[Parameter(Mandatory=$true)] [string]$attrToken
    )

    $params = @{
        body =  @{
            "jsonrpc"= "2.0"
            "method"= "user.logout"
            "params" = @{}
            "id"= 1
            "auth"= "$attrToken"
        } | ConvertTo-Json
        uri = "$attrZabbixServer"
        headers = @{"Content-Type" = "application/json"}
        method = "Post"
    }

    Try {
        $result = Invoke-WebRequest @params 
        Write-Host $result
        $auth = ($result.Content | ConvertFrom-Json).result
        
        Return $auth
    } Catch {
        Return $null
    }

}

Function New-ZabbixHostSNMP {
  Param (
        [Parameter(Mandatory=$true)] [string]$attrZabbixServer
        ,[Parameter(Mandatory=$true)] [string]$attrToken
        ,[Parameter(Mandatory=$true)] [string]$attrHostname
        ,[Parameter(Mandatory=$true)] [string]$attrIP
		,[Parameter(Mandatory=$true)] [string]$attrGroupID
		,[Parameter(Mandatory=$true)] [string]$attrProxyID
		,[Parameter(Mandatory=$true)] [string]$attrTemplateID

    )

    $params = @{
        body =  @{
            "jsonrpc"= "2.0"
            "method"= "host.create"
            "params"= @{
                "host"= "$attrHostname"
                "interfaces"= @{
                        "type"= 2
                        "main"= 1
                        "useip"= 1
                        "ip"= "$attrIP"
                        "dns" = ""
                        "port"= "161"
                        "details" = @{
                            "version"= 2
                            "bulk"= 0
                            "community"= '{$SNMP_COMMUNITY}'
                        }
                }
                "groups"= @{
                        "groupid"= "$attrGroupID"
                }
                "templates"= @{
                        "templateid"= "$attrTemplateID"
                }
                "macros"= @{
                        "macro"= '{$SNMP_COMMUNITY}'
                        "value"= "bioWsn-p"
                } 
                "proxy_hostid" = $attrProxyID
            }
            "id"= 1
            "auth"= "$attrToken"
        } | ConvertTo-Json -Depth 3
        uri = "$attrZabbixServer"
        headers = @{"Content-Type" = "application/json"}
        method = "Post"
    }

    Try {
        $result = Invoke-WebRequest @params 
        Write-Host $result
        
        Return $result
    } Catch {
        Write-Host $Error[0]
        Return $null
    }

}

Function New-ZabbixHostAgent {
    Param (
          [Parameter(Mandatory=$true)] [string]$attrZabbixServer
          ,[Parameter(Mandatory=$true)] [string]$attrToken
          ,[Parameter(Mandatory=$true)] [string]$attrHostname
          ,[Parameter(Mandatory=$true)] [string]$attrIP
		  ,[Parameter(Mandatory=$true)] [string]$attrGroupID
		  ,[Parameter(Mandatory=$true)] [string]$attrProxyID
		  ,[Parameter(Mandatory=$true)] [string]$attrTemplateID
  
      )
  
      $params = @{
          body =  @{
              "jsonrpc"= "2.0"
              "method"= "host.create"
              "params"= @{
                  "host"= "$attrHostname"
                  "interfaces"= @{
                          "type"= 1
                          "main"= 1
                          "useip"= 1
                          "ip"= "$attrIP"
                          "dns" = ""
                          "port"= "10050"
                  }
                  "groups"= @{
                          "groupid"= "$attrGroupID"
                  }
                  "templates"= @{
                          "templateid"= "$attrTemplateID"
                  }
                  "proxy_hostid" = $attrProxyID
              }
              "id"= 1
              "auth"= "$attrToken"
          } | ConvertTo-Json -Depth 3
          uri = "$attrZabbixServer"
          headers = @{"Content-Type" = "application/json"}
          method = "Post"
      }
  
      Try {
          $result = Invoke-WebRequest @params 
          Write-Host $result
          
          Return $result
      } Catch {
          Write-Host $Error[0]
          Return $null
      }
  
  }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Error.clear()
$url = $attrURL
$credential = Get-Credential -UserName $attrZabbixUser -message 'Zabbix account with API rights'

# disable warning TLS
$code= @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Prihlaseni k Zabbix serveru
$token = Get-LoginZabbix -attrZabbixServer $url  -attrCredentials $credential
If ($null -eq $token) {
    exit
}

# import CSV
$CSV = Import-CSV -path $attrHostCSV -Delimiter ','

ForEach ($line in $CSV) {
    Write-Verbose "Create host $($line.host)"
    New-ZabbixHostAgent -attrZabbixServer $url -attrToken $token -attrHostname $line.host -attrIP $line.ip -attrGroupID $attrGroupID -attrTemplateID $attrTemplateID -attrProxyID $attrProxyID
}

# Odhlaseni
Get-LogoutZabbix -attrZabbixServer $url -attrToken $token
