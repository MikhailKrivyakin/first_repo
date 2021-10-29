#!/bin/bash
totalOK=0
total=0
totalEr=0
echo -e 'Counter v1.4: \n'
if [ $(tail out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then 
	current_step_number=$(tail -n 20 ..//06-upgrade-posclients/out-runlog.txt | grep "RUNNING STEP"|cut -c 19-20)
	echo -e 'Workflow was stopped. Check Errors\n'
else
	current_step_number=$(tail ..//06-upgrade-posclients/out-runlog.txt | grep "RUNNING STEP"|cut -c 19-20)
fi
	#check if any output log exists 

		echo 'Site		OK/ALL	 	Failed'
		for site in $(cat sites.list)
			do
				#+1 needed cause if we`re cheking step 06, there are already 1 upgraded till #1
				count=$(($(cat ../06-upgrade-posclients/posclients.list | grep $site | wc -l)+1)) # count in common per store
					ok_count=$(($(cat ../06-upgrade-posclients/*$current_step_number*/out-posclients-ok.list | grep $site |wc -l)+1)) #counting OK tills
				error_count=0
					#checking if any failed till is exist
					if [ -e ../06-upgrade-posclients/*$current_step_number*/out-posclients-error.list ]
						then 		
							#counting error tills
						
								error_count=$(($(cat ../06-upgrade-posclients/*$current_step_number*/out-posclients-error.list |grep $site | wc -l)))  #counting error tills
								totalEr=$(($totalEr+$error_count))
							
					fi
				echo "$site		$ok_count / $count	 	$error_count" 
				totalOK=$(($totalOK+$ok_count))
				total=$(($total+$count))
			
			done
		echo -e "---------------------------------\nTotal		$totalOK / $total	 	$totalEr"
		

	
	
	
#v.1.1
#		added Total count 
#v.1.2
#		managed to work from 00-automation
#		added check for refresh start
#v1.3  
#		now it`s not only looking after refresh step, but after workflows current step!!!
	# thanks a lot for usiong this script. It means i didn`t waste my time for nothing and i owe you a cookie
#v1.4 
#	added check in lines 5-9 in cause of WF crashed. In this case - counter will display last runned steps data