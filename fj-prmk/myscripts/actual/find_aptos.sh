#!/bin/bash

function f_ping_aptos
{
        
        name=$(echo $1 | cut -c 1-6)
        if [[ $(echo $name |grep -c "000") -gt 0 ]];then
             ip=$(echo $1 | cut -c 41-48)150
        elif [[ $(echo $name |grep -c "....0.") -gt 0 ]] || [[ $(echo $name |grep -c "..00") -gt 0 ]]; then
            
            ip=$(echo $1 | cut -c 41-49)150
            
        else 
            ip=$(echo $1 | cut -c 41-50)150
        fi
				state="Aptos not found"
			result=$(ping -c 2 -W 2 $ip)
        
				#find if till is UP
				if [ $? -eq 0 ];then
				state="Warning! APTOS server found!"
     
			fi
   
    # 
			echo "${name:0:6} | $state $ip"

}
rm store_IP.list
for site in $(cat sites.list)
    do
        profuse unit show $site| grep "POS Server" >> store_IP.list
    done
  
export -f f_ping_aptos

cat store_IP.list | parallel --no-notice f_ping_aptos {} 