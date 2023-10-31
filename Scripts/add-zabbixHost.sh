#!/bin/bash
 IP=$1  
 HOST_NAME=$2  
 HOSTGROUPID=$3
 TEMPLATEID=$4
 
 # CONSTANT VARIABLES  
 ERROR='0'  
 ZABBIX_USER='Admin' 
 ZABBIX_PASS='zabbix' 
 ZABBIX_SERVER='smon' 
 API='https://smon/api_jsonrpc.php'  
 
 # Authenticate with Zabbix API    
 authenticate() {  
         echo `curl -k -s -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\": \"2.0\",\"method\":\"user.login\",\"params\":{\"user\":\""${ZABBIX_USER}"\",\"password\":\""${ZABBIX_PASS}"\"},\"auth\": null,\"id\":0}" $API`  
     }   
 AUTH_TOKEN=`echo $(authenticate)|jq -r .result`   
 
 # Create Host  
 create_host() {  
         echo `curl -k -s -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\": {\"host\":\"$HOST_NAME\",\"interfaces\": [{\"type\": 1,\"main\": 1,\"useip\": 1,\"ip\": \"$IP\",\"dns\": \"\",\"port\": \"10050\"}],\"groups\": [{\"groupid\": \"$HOSTGROUPID\"}],\"templates\": [{\"templateid\": \"$TEMPLATEID\"}]},\"auth\":\"$AUTH_TOKEN\",\"id\":1}" $API`  
     }  
 output=$(create_host)  
 echo $output | grep -q "hostids"  
 rc=$?  
 if [ $rc -ne 0 ]  
  then  
      echo -e "Error in adding host ${HOST_NAME} at `date`:\n"  
      echo $output | grep -Po '"message":.*?[^\\]",'  
      echo $output | grep -Po '"data":.*?[^\\]"'  
      exit  
 else  
      echo -e "\nHost ${HOST_NAME} added successfully\n"  
      # start zabbix agent  
      #service zabbix-agent start  
      exit  
 fi  
