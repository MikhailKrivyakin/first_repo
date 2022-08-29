#!/bin/bash
echo "Hostname    IP"
for site in $(cat sites.list)
do
 name=$(profuse unit show $site |grep "POS Server" |cut -c 1-10)
 ip=$(profuse unit show $site |grep "POS Server" |cut -c 48-61)
 echo "$name  $ip"
done