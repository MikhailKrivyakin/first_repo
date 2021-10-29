#!/bin/bash
#check if WF was running
if [ -e out-runlog.txt ]; then
	#check if WF was completed
	if [ $(tail out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ]; then
		echo 'Workflow finished'
	else
		#display current step from out-runlog
		echo -e "**********Current step is: $(tail ..//06-upgrade-posclients/out-runlog.txt | grep "RUNNING STEP"|cut -c 19-60) ********************************************************\n"
	
		#run scripts
		echo -e "Counter:\n  " && ../00-automation/./counter.sh && echo -e "\n Errors parser:\n" && ../00-automation/./logs_parser.sh
	fi	
else
	#if no outputs then message
	echo "Upgrade has not started yet"
fi	

#####################################################
#####################################################