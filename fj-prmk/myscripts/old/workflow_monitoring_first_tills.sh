#!/bin/bash
#check if WF was running
if [ -e out-runlog.txt ]; then
	#check if WF was completed
	if [ $(tail out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then
		echo 'Workflow finished'
	else
		#display current step from out-runlog
		echo -e "**********Current step is: $(tail ..//06-upgrade-posclients/out-runlog.txt | grep "RUNNING STEP"|cut -c 19-60) ********************************************************\n"
	
		#run scripts
		../00-automation/./counter.sh && echo -e '\n*********************************\n' && ../00-automation/./logs_parser.sh
	fi	
else
	#if no outputs then message
	echo "Upgrade has not started yet"
fi	

#v 1.1
#		line 5: second condition was added, so user be able to see logs in case of WF crashing
#		line 9: deleted titles from display
#####################################################
#####################################################