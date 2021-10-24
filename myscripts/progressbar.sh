#!/bin/bash

#		script for monitor Workflow process by percent for each till by Mikhail Krivyakin
#		script uses log file for till 1 in each store as the sample and calculating percents regarding to current till log file size.
#		If log file for current till wasnt changed in 10 minutes you`ll see Warning message
#		please enjoy, and feel free to contack me in case of any bugs



#check if WF was running
if [ -e out-runlog.txt ]; then
	./status.sh > steps.count.progress
	total_steps=$(($(cat steps.count.progress |wc -l)-3))
#title
	echo -e "						Upgrade progress bar v1 by Mikhail Krivyakin"
	echo -e "---------------------- Current step is: $(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20) / $total_steps.  ----------------------------------------\n"
	echo -e "----------------------$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:') --------------------------------------------"
#----------------------------------------------------------------------------------------------------------------------------
#---Check if WF was stopped
if [ $(tail out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then 
	current_step_number=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)
	echo -e 'Workflow was stopped. Check Errors'
fi

	
	
	current_step_number=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)				#find current step number
	current_step_name=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')	#find current_step_name
	#start cycle for each site
	for site in $(cat sites.list)
		do
		count_per_rows=1
		#title
		
			
			#calculating count per store using part of the counter.sh script
		
		count=$(($(cat posclients.list | grep $site | wc -l)+1)) # count in common per store
		{
		ok_count=$(($(cat *$current_step_number*/out-posclients-ok.list | grep $site |wc -l)+1))  #counting OK tills
		}&>/dev/null
		error_count=0
		#checking if any failed till is exist
		echo -en "\n\n$site [$ok_count]/[$count]"
		
		if [ -e *$current_step_number*/out-posclients-error.list ] && [ $(cat *$current_step_number*/out-posclients-error.list |grep $site |wc -l) -gt 0 ];then 		
				#counting error tills
					error_count=$(($(cat *$current_step_number*/out-posclients-error.list |grep $site | wc -l)))  #counting error tills
				echo -n " ERROR [$error_count]"
		fi
		
		echo -en ':\n'
		echo "---------------------------------------------------------------------------------------------------------"
		echo -n $site"t001 [100] OK!	"
			#start cycle for each till in this store----------------------------------------------------------------------
			for till in $(cat posclients.list|grep $site)
				do  
				if [ -e *$current_step_name*/out-log/$till.txt ];then
				warning=0
				time=$((`date +%s` - `date -r *$current_step_name*/out-log/$till.txt +%s`))
				{
				#check for changes in 10 minutes and if file is not OK yet				
				if [ $time -gt 600 ] && [ $(cat *$current_step_name*/out-posclients-ok.list|grep $till|wc -l ) -eq 0 ] ; then
					warning=1
				fi
				}&>/dev/null
					currentsise=$(stat -c%s *$current_step_number*/out-log/$till.txt)							#current size
					examplesize=$(stat -c%s ../*upgrade-till-1/*$current_step_number*/out-log/$site*t001.txt) 	#example size, that was tooked from the 1st till in this store
					
					percents=$(($currentsise*100/$examplesize))													#current percent
				
				#check if this till in error list
			
			if [ -e *$current_step_name*/out-posclients-error.list ] && [ $(cat *$current_step_name*/out-posclients-error.list|grep $till|wc -l ) -gt 0 ];then
					echo -n "$till [$percents] ERROR!	"
					count_per_rows=$(($count_per_rows+1))
				#check if already 100%
				elif [[ $percents -gt 99 ]]; then
					echo -n "$till [$percents] OK!	"
					count_per_rows=$(($count_per_rows+1))
			#check for changes in 10 minutes and if file is not OK yet	
				elif [[ $warning -eq 1 ]];then
					echo -n "$till [$percents] WARNING!"
					count_per_rows=$(($count_per_rows+1))
				else	
					#display results and +1 for till in 1 row counter
					echo -n "$till [$percents]		"
					count_per_rows=$(($count_per_rows+1))
					#reseting rows counter, when >3
				fi
				#next row________________________
					if [ $count_per_rows -gt 3 ]; then						
						echo ""
						count_per_rows=0
					fi
					fi
				#________________________________________	
				done
				
		done
#----------------------------------------------------------------------------------------------------------------------------




else
	#if no outputs then message
	echo -e "   									Upgrade progress bar v.1 by Mikhail Krivyakin\n--------------------------------Upgrade has not started yet-----------------------------  "
	
fi
