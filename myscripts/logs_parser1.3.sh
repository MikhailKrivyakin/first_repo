#!/bin/bash
#delete files from previos check

rm error_log 2>/dev/null 
echo -e 'Errors parser v1.3\n '
#check if WF is running
if [ -e ../06-upgrade-posclients/out-runlog.txt ]; then
	#check if any error-list exists 
	current_step_number=$(cat ../06-upgrade-posclients/out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)
	if [ -e ../06-upgrade-posclients/*$current_step_number*/out-posclients-error.list ]; then
		#title of result file
		echo -e "**********************************************\nThose tills has lockdown issue, keep calm and:\n1.reboot this tills.\n2.Re-run this WF step\n" >> error_log
		#checking out error-list and their logs, pooting lockdown and other errors to separate files
		for till in $(cat ../06-upgrade-posclients/*$current_step_number*/out-posclients-error.list)
			do
				# if rows count with "lockdown > 0 than its lockdown"
				if [ "$(tail ../06-upgrade-posclients/*$current_step_number*/out-log/$till.txt |grep 'ensure template for 'locked' is applied as system'|wc -l)" -gt 0 ]; then 
					echo -e "$till" >> lockdown.list 
				else 
					echo -e "\t_______ failed __________\t\n" >> other_errors #else it`s some kind of other error and needs invistigation
					echo "$till :" >> other_errors
					tail ../06-upgrade-posclients/*$current_step_number*/out-log/$till.txt >>other_errors
					
				fi
			
			done
	# combining files to error_log	
	{
		cat lockdown.list |tr '\n' ':'	>> error_log 
		}&>/dev/null
		echo '' >> error_log
		if [ -e other_errors ]; then
			echo -e '\n \n******************************************\n\nOther failed tills: \n ' >> error_log
			cat other_errors >> error_log
			rm other_errors
		fi
		# removing unnececary files

		rm lockdown.list 2>/dev/null

		#display result
		cat error_log
	else
		echo -e "There are no errors in your workflow...yet\n"
	fi	
else
		#if no outputs then message
		echo "Upgrade has not started yet"
fi	
# v1.1. 
#		Added check for *errors* files existing 
#v1.2
#		managed to work from 00-automation 		
#v1.3  
#		now it`s not only looking after refresh step, but after workflows current step!!!
#		added title with current version. little displaing fixes
#		21.10 - sort changed to cat. Clarifed condition for lockdown tills.Logics of finding current step number changed