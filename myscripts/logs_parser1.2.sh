#!/bin/bash
#delete files from previos check

rm error_log 2>/dev/null 
#title of result file


#check if any error-list exists 
if [ -e ../06-upgrade-posclients/*refresh*/out-posclients-error.list ]; then
	echo -e "**********************************************\nThose tills has lockdown issue, keep calm and:\n1.reboot this tills.\n2.Re-run this WF step\n" >> error_log
	#checking out error-list and their logs, pooting lockdown and other errors to separate files
	for till in $(cat ../06-upgrade-posclients/*refresh*/out-posclients-error.list)
		do
			# if rows count with "lockdown > 0 than its lockdown"
			if [ "$(tail ../06-upgrade-posclients/*refresh*/out-log/$till.txt |grep 'locked'|wc -l)" -gt 0 ]; then 
				echo -e "$till" >> lockdown.list 
			else 
				echo -e "\t_______ failed __________\t\n" >> other_errors #else it`s some kind of other error and needs invistigation
				echo "$till :" >> other_errors
				tail ../06-upgrade-posclients/*refresh*/out-log/$till.txt >>other_errors
				
			fi
		
		done
# combining files to error_log	
	sort lockdown.list |tr '\n' ':'	>> error_log
	echo '' >> error_log
	if [ -e other_errors ]; then
		echo -e '\n \n******************************************\n\nOther failed tills: \n ' >> error_log
		cat other_errors >> error_log
		rm other_errors
	fi
	# removing unnececary files

	rm lockdown.list

	#display result
	cat error_log
else
	echo "There is no errors in your workflow...yet"
fi	

# v1.1. 
#		Aded check for *errore* files existing 
#v1.2
#		managed to work from 00-automation 		