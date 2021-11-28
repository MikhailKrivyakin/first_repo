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
                        
                       echo  "$name is up (Toshiba)"
                        
                elif [[ $(echo $state) == "UP"  &&  $(echo $result | grep DUP |wc -l) -eq 0 ]]; then
                        
                        echo  "$name is up (Aptos)"
                        
                        
                else
                       echo  "$name is down"
                fi

}
export -f ping_till
#gathering tills from selected sites
for site in $(cat sites.list)
    do
        profuse unit show $site| grep Till > tills_IP.list
    done
echo ''
date
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
cat tills_IP.list | parallel --no-notice ping_till {} |sort
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo Done
rm tills_IP.list; #remove trash


#\E[32;40m