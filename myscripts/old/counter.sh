#!/bin/bash
echo 'Site		OK/ALL	 	Failed'
for site in $(cat sites.list)
	do
	#count begins from 1 cause if we`re cheking step 06, there are already 1 upgraded till #1
	count=1
	ok_count=1
	error_count=0
		for till in $(cat posclients.list | grep $site) # count in common per store
			do
				count=$(($count+1))
			done
		#counting OK tills
		for till in $(cat *refresh*/out-posclients-ok.list | grep $site)
			do
				ok_count=$(($ok_count+1))
			done
		#checking if any failed till is exist
		if [ -e *refresh*/out-posclients-error.list ]
			then 		
				#counting error tills
				for till in $(cat *refresh*/out-posclients-error.list |grep $site)
					do
						error_count=$(($error_count+1))
					done
			fi
		echo "$site		$ok_count / $count 		$error_count"
	done
	
	
	
	
	
	
	
	
	# thanks a lot for usiong this script. It means i didn`t waste my time for nothing and i owe you a cookie