#!/bin/bash
totalOK=0
total=0
totalEr=0
echo 'Site		OK/ALL	 	Failed'
for site in $(cat sites.list)
	do
	#+1 needed cause if we`re cheking step 06, there are already 1 upgraded till #1
	count=$(($(cat posclients.list | grep $site | wc -l)+1)) # count in common per store
	ok_count=$(($(cat *refresh*/out-posclients-ok.list | grep $site |wc -l)+1)) #counting OK tills
	error_count=0
		#checking if any failed till is exist
		if [ -e *refresh*/out-posclients-error.list ]
			then 		
				#counting error tills
				
						error_count=$(($(cat *refresh*/out-posclients-error.list |grep $site | wc -l)))  #counting error tills
						totalEr=$(($totalEr+$error_count))
					
			fi
		echo "$site		$ok_count / $count 		$error_count" 
		totalOK=$(($totalOK+$ok_count))
		total=$(($total+$count))
					
	done
echo -e "---------------------------------\nTotal		$totalOK / $total			$totalEr"
	
	
	
	
	
#v.1.1
#		added Total count 
	
	# thanks a lot for usiong this script. It means i didn`t waste my time for nothing and i owe you a cookie