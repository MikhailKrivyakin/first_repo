#!/bin/bash

#		script for monitor Workflow process by percent for each till by Mikhail Krivyakin
#		script uses log file for till 1 in each store as the sample and calculating percents regarding to current till log file size.
#		If log file for current till wasnt changed in 10 minutes you`ll see Warning message
#		please enjoy, and feel free to contack me in case of any bugs

function progressbar
{
title_chars_number=$(($(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:'|wc -m)/2))
#check if WF was running
if [ -e out-runlog.txt ]; then
	#./status.sh > steps.count.progress
	total_steps=$(($(./status.sh |wc -l)-3))
	current_step_number=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)				#find current step number
	current_step_name=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')	#find current_step_name
	accurate_step_name=$(echo $current_step_name | cut -c 3-)
	step_percent=0
	
#title
	echo -e "						Upgrade progress bar v1.5 by Mikhail Krivyakin"
	echo -e " $(for (( i = 0; i < 37; i++ ))do echo -n "-"; done; ) Current step is: $(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20) / $total_steps. $(for (( i = 63; i < 101; i++ ))do echo -n "-"; done; )\n"
	echo -e " $(for (( i = 0; i < $(( 50-$title_chars_number)); i++ ))do echo -n "-"; done; ) $(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:') $(for (( i = $(( 50+$title_chars_number)); i < 101; i++ ))do echo -n "-"; done; )"
		#progressbar display
		if [ -e *$current_step_number*/out-*-ok.list ];then			
		{
			step_percent=$(( $(cat *$current_step_number*/out-*-ok.list |wc -l)*100/$(cat posclients.list |wc -l) ))
		}&>/dev/null
			echo -ne "\n[ $(for (( i = 0; i < $step_percent; i++ ))do echo -n "="; done; ) $(for (( i = $step_percent; i < 100; i++ ))do echo -n "-"; done; )]($step_percent%)"
			echo ''
		fi
#----------------------------------------------------------------------------------------------------------------------------
#---Check if WF was stopped
if [ $(tail out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then 
	current_step_number=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)
	echo -e 'Workflow was stopped. Check Errors'
fi
	 
	
	
	
	
	#start cycle for each site
	for site in $(cat sites.list)
		do
		count_per_rows=1
		#title
		
			
			#calculating count per store using part of the counter.sh script
		
		count=$(($(cat posclients.list | grep $site | wc -l)+1)) # count in common per store
		{
		ok_count=$(($(cat *$current_step_number*/out-*-ok.list | grep $site |wc -l)+1))  #counting OK tills
		}&>/dev/null
		error_count=0
		#checking if any failed till is exist
		echo -en "\n\n$site [$ok_count]/[$count]"
		
		if [ -e *$current_step_number*/out-*-error.list ] && [ $(cat *$current_step_number*/out-*-error.list |grep $site |wc -l) -gt 0 ];then 		
				#counting error tills
					error_count=$(($(cat *$current_step_number*/out-*-error.list |grep $site | wc -l)))  #counting error tills
				echo -n " ERROR [$error_count]"
		fi
		
		echo -en ':\n'
		echo " ---------------------------------------------------------------------------------------------------------"
		echo -n $site"t001 [100] OK!	"
			#start cycle for each till in this store----------------------------------------------------------------------
			for till in $(cat posclients.list|grep $site)
				do  
				warning=0
				if [ -e *$current_step_name*/out-log/$till.txt ];then											#check if log file for till exist
					
					time=$((`date +%s` - `date -r *$current_step_name*/out-log/$till.txt +%s`))
					
					#check for changes in 10 minutes and if file is not OK yet				
						if [ $time -gt 600 ] && [ $(cat *$current_step_name*/out-*-ok.list|grep $till|wc -l ) -eq 0 ] ; then
							warning=1
						fi
					
					currentsise=$(stat -c%s *$current_step_number*/out-log/$till.txt)								#current size
					
					if [ -e ../*upgrade-till-1/*$accurate_step_name*/out-log/$site*t001.txt ];then
						examplesize=$(stat -c%s ../*upgrade-till-1/*$accurate_step_name*/out-log/$site*t001.txt) 	#example size, that was tooked from the 1st till in this store
						percents=$(($currentsise*100/$examplesize))													#current percent
					else 
					################################################################################################################################
					##			algoritm for finding tills log file in run-00* directories. in case there was few re-runs during upgrade of till 1
					#################################################################################################################################
						
						run_number=$(ls -l ../*upgrade-till-1/*$accurate_step_name*/ |grep run |tail -1 | cut -c 48) #finding maximun run number
						for (( i=$run_number;i>0;i-- )) 															 # from the lates to newest run start searching for succesfull log file
						do
							if [ -e ../*upgrade-till-1/*$accurate_step_name*/run-00$i/out-log/$site*t001.txt ] && [ $(tail ../*upgrade-till-1/*$accurate_step_name*/run-00$i/out-log/$site*t001.txt | grep RET=0 | wc -l) -gt 0 ]; then
								examplesize=$(stat -c%s ../*upgrade-till-1/*$accurate_step_name*/run-00$i/out-log/$site*t001.txt)	#calculating percents
								percents=$(($currentsise*100/$examplesize))															#
															
							fi
						done
					fi
					##################################################################################################
					elif [ $(cat *$current_step_name*/out-*-ok.list|grep $till|wc -l ) -gt 0 ];then		#if already in OK list - then 100%
						percents=100	
					else
						percents=0
					
																											# till has not started yet
					fi
				#check if this till in error list
				
			if [ -e *$current_step_name*/out-*-error.list ] && [ $(cat *$current_step_name*/out-*-error.list|grep $till|wc -l ) -gt 0 ];then
					echo -n "$till [$percents] ERROR!	"
					count_per_rows=$(($count_per_rows+1))
				#check if already 100%
				elif [ $(cat *$current_step_name*/out-*-ok.list|grep $till|wc -l ) -gt 0 ]; then
					if [ $percents -eq 100 ];then				#
						echo -n "$till [$percents] OK!	"		#
					else 										#in some cases OK log maybe lesser,then 100%. To avoid unstuctiring output 
						echo -n "$till [$percents]  OK!	"		#added this if-else
					fi
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
					
				#________________________________________	
				done
				
		done
#----------------------------------------------------------------------------------------------------------------------------


rm steps.count.progress 2>/dev/null

else
	#if no outputs then message
	echo -e "   									Upgrade progress bar v.1.5 by Mikhail Krivyakin\n--------------------------------Upgrade has not started yet-----------------------------  "
	
fi

#v 1.4.
#	succesfull log searching algoritm added.
####
}
export -f progressbar
watch -n5  progressbar