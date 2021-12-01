#!/bin/bash


function ping_till
{				
				ip=$(echo $1 | cut -c 38-51)
                name=$(echo $1| cut -c 1-10)
				state="unknown"
				result=$(ping -c 5 -W 5 $ip)
                
				#find if till is UP
				if [ $? -eq 0 ];then
					 echo "$name is up"
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
