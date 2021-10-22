#!/bin/bash
totalOK=0
total=0
totalEr=0
#check if any output log exists 
if [ -e ../06-upgrade-posclients/*refresh*/out-log ]; then
echo 'Site		OK/ALL	 	Failed'
for site in $(cat sites.list)
	do
	 	#+1 needed cause if we`re cheking step 06, there are already 1 upgraded till #1
		count=$(($(cat ../06-upgrade-posclients/posclients.list | grep $site | wc -l)+1)) # count in common per store
		ok_count=$(($(cat ../06-upgrade-posclients/*refresh*/out-posclients-ok.list | grep $site |wc -l)+1)) #counting OK tills
		error_count=0
			#checking if any failed till is exist
			if [ -e ../06-upgrade-posclients/*refresh*/out-posclients-error.list ]
				then 		
					#counting error tills
				
						error_count=$(($(cat ../06-upgrade-posclients/*refresh*/out-posclients-error.list |grep $site | wc -l)))  #counting error tills
						totalEr=$(($totalEr+$error_count))
					
			fi
		echo "$site		$ok_count / $count 		$error_count" 
		totalOK=$(($totalOK+$ok_count))
		total=$(($total+$count))
	
	done
echo -e "---------------------------------\nTotal		$totalOK / $total			$totalEr"
else
	#if no outputs then message
	echo "Refresh has not started yet"
	fi	
	
	
	
	
#v.1.1
#		added Total count 
#v.1.2
#		managed to work from 00-automation
#		added check for refresh start
	# thanks a lot for usiong this script. It means i didn`t waste my time for nothing and i owe you a cookie