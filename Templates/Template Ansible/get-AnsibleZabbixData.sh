#!/bin/bash

# ziskej unikatni hostname z ansible
data=$(cat $1 | grep -oE '\|.(.*[a-zA-Z]).*\:.ok' | grep -oE '[a-zA-Z.][^ ]*' | grep -vwE "ok" | sort -u )

# pro kazdy radek udelej ...
while IFS= read -r line; do
    data1+="{\"{#SERVERNAME}\":\"$line\"},"
done <<< "$data"

# odeber posledni znak
data1=${data1::-1}

# pridej hranate zavorky
returnJson="[$data1]"
echo "$returnJson"
 
