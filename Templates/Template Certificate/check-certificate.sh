#!/bin/bash

if [ "$2" = "geturl" ] ; then
		# return JSON data for input string
        printf '{"data":['
        for i in $(echo $1 | tr ";" "\n")
        do
                url+='{"{#URL}":"'$i'"},'
        done
        printf ${url:0:${#url}-1}
        printf "]}"
else
		# return number of days to expire certificate
        endDate=$(echo | openssl s_client -servername $1 -connect $1:443 2>/dev/null | openssl x509 -noout -enddate | sed "s/.*=\(.*\)/\1/" )
        date_s=$(date -d "${endDate}" +%s)
        now_s=$(date -d now +%s)
        date_diff=$(( (date_s - now_s) / 86400 ))
        echo "$date_diff"
fi