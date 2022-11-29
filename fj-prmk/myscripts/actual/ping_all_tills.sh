#!/bin/bash


function ping_till
{				
				ip=$(echo $1 | cut -c 39-49)
                name=$(echo $1 | cut -c 1-11)
				state="unknown"
				result=$(ping -c 5 -W 5 $ip)
				#find if till is UP
				if [ $? -eq 0 ];then
					state="UP"
				fi
				#find what type of till is it
          
			  	if [[ $(echo $state) == "UP"  &&  $(echo $result | grep DUP |wc -l) -gt 0 ]]; then
                       echo "$name is up (Toshiba)"
                elif [[ $(echo $state) == "UP"  &&  $(echo $result | grep DUP |wc -l) -eq 0 ]]; then
                        echo "$name is up (Aptos)"
                else
                       echo "$name is down"
                fi

}


 export -f ping_till
 echo ''
date
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
profuse unit show $1| grep Till | parallel --no-notice ping_till {} |sort
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo Done
