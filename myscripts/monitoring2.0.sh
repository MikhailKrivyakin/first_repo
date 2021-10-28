#!/bin/bash
#
#	script for monitor WF upgrade by Mikhail krivyakin
#	please enjoy, and feel free to contack me in case of any bugs
#
#

#check if WF was running
if [ -e out-runlog.txt ]; then
#_______________________________________________________________________________
#check if WF was completed
if [ $(tail out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then
	echo -e "   									$1	WF monitoring v2 by Mikhail Krivyakin\n"
	echo -e "\n------------------------------Workflow finished, hope you have enjoyed it-----------------------------  "
else
#---------------------------------------------------------------------------------
	current_step_number=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)
	current_step_name=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')
	./status.sh > steps.count						#
	total_steps=$(($(cat steps.count |wc -l)-3))	# find total step number, using ./status output
if [[ $(pwd) == *"server"* ]];then
	unit_type="server"
elif [[ $(pwd) == *"client"* ]];then
	unit_type="client"
elif [[ $(pwd) == *"till-1"* ]];then
	unit_type="client"	
fi	
	#display current step from out-runlog and title
	echo -e "   								$1	WF monitoring v2 by Mikhail Krivyakin  "
	echo -e "---------------------- Current step is: $current_step_number / $total_steps  ----------------------------------------\n"
	echo -e "----------------------$current_step_name --------------------------------------------"


############# Starting counter code
	totalOK=0
	total=0
	totalEr=0
	
	#check if WF was stopped
	if [ $(tail out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then 
		echo -e 'Workflow was stopped. Check Errors'			
	fi
	#choosing title regarding of unit type
	if [[ $unit_type == "server" ]] || [[ $(pwd) == *"till-1"* ]]; then
		echo -e '\nProgress per site: \n---------------------------------\nSite		OK/ALL	 	   Failed'

	else
		echo -e '\nProgress per site, including till#1\n---------------------------------\nSite		OK/ALL	 	   Failed'
	fi
#------------------------------------------------------------------------------------
#start cycle for each stoe in sites.list			
		for site in $(cat sites.list)
			do	
			
				#+1 needed cause if we`re cheking step 06, there are already 1 upgraded till #1
				{
				count=$(($(cat *$unit_type*.list | grep $site | wc -l)+1)) # count in common per store
				ok_count=$(($(cat *$current_step_name*/out-*-ok.list | grep $site |wc -l)+1))  #counting OK tills
				}&>/dev/null
				error_count=0
					#checking if any failed till is exist
					if [ -e *$current_step_number*/out-*-error.list ]
						then 		
							#counting error tills
						
								error_count=$(($(cat *$current_step_number*/out-*-error.list |grep $site | wc -l)))  #counting error tills
								totalEr=$(($totalEr+$error_count))
							
					fi
					
				#removing +1, in case if we are upgrading server or till 1
				if [[ $unit_type == "server" ]] || [[ $(pwd) == *"till-1"* ]]; then
					count=$(($count-1))
					ok_count=$(($ok_count-1))

				fi
				#---------------------------------------------------------------
				
				echo "$site		$ok_count / $count			$error_count" 
				totalOK=$(($totalOK+$ok_count))
				total=$(($total+$count))
			done
		echo "---------------------------------"
		echo  Total"		"$totalOK / $total"			"$totalEr


		
###############Starting parser code
	if [ -e *$current_step_number*/out-*-error.list ]; then
		#title of result file
		if [[ $1 == "auto" ]];then
			echo -e "**********************************************\nThose units has lockdown issue.They should be already rebooted by this script" >> error_log 
		else
			echo -e "**********************************************\nThose units has lockdown issue, keep calm and:\n1.reboot this tills.\n2.Re-run this WF step\n" >> error_log 
		fi
		
		#checking out error-list and their logs, puting lockdown and other errors to separate files
		for unit in $(cat *$current_name*/out-*-error.list)
			do
				# if rows count with "lockdown > 0 than its lockdown"
			if [ "$(tail *$current_step_number*/out-log/$unit.txt |grep "ensure template for 'locked' is applied as system"|wc -l)" -gt 0 ] && [ $(echo "$current_step_name"|grep refresh |wc -l) -gt 0 ]; then 
				#check: auto reboot mode or not
				{
				if [[ $1 == "auto" ]] && [ $(cat rebooted.list |grep $unit |wc -l) -eq 0 ];then
					echo -n ":$unit" >> lockdown.list 
					profuse task run run-command-pos$unit_type $unit 'shutdown -r -t 0' >/dev/null						
					echo "$unit" >> rebooted.list
				else
					echo -n ":$unit" >> lockdown.list 
				fi
				}&>/dev/null
			else 
				echo -e "\t_______ failed __________\t\n" >> other_errors #else it`s some kind of other error and needs invistigation
				echo "$unit :" >> other_errors
				tail *$current_step_number*/out-log/$unit.txt >>other_errors
					
			fi			
			done
	# combining files to error_log	
	{
		cat lockdown.list >> error_log  #|tr '\n' ':'
		}&>/dev/null
		echo '' >> error_log
		if [ -e other_errors ]; then
			echo -e '\n \n******************************************\n\nOther failed tills: \n ' >> error_log
			cat other_errors >> error_log
			rm other_errors
		fi
		#display result
		cat error_log
	else
		echo -e "There are no errors in your workflow...yet\n"
	fi	


#-------------------------------------------------------------------------------
#removing unneccecary files
	rm steps.count 2>/dev/null
	rm error_log 2>/dev/null 
	rm lockdown.list 2>/dev/null
#---------------------------------------------------------------------------------
fi

#_______________________________________________________________________________
else
	#if no outputs then message
	echo -e "   							$1		WF monitoring v2 by Mikhail Krivyakin\n--------------------------------Upgrade has not started yet-----------------------------  "
	
fi	