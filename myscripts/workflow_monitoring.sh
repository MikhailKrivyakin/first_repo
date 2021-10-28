#!/bin/bash
#check if WF was running
if [ -e out-runlog.txt ]; then
	#check if WF was completed
	if [ $(tail out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then
		echo -e "   										WF monitoring v1.2 by Mikhail Krivyakin\n"
		echo -e "\n------------------------------Workflow finished, hope you have enjoyed it-----------------------------  "
		
	else
		./status.sh > steps.count
		total_steps=$(($(cat steps.count |wc -l)-3))
		#display current step from out-runlog
		echo -e "   									WF monitoring v1.2 by Mikhail Krivyakin  "
		echo -e "---------------------- Current step is: $(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20) / $total_steps  ----------------------------------------\n"
		echo -e "----------------------$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:') --------------------------------------------"
	
		#run scripts
		../00-automation/./counter.sh && echo -e '\n*********************************\n' && ../00-automation/./logs_parser.sh
	fi	
else
	#if no outputs then message
	echo -e "   									WF monitoring v1.2 by Mikhail Krivyakin\n--------------------------------Upgrade has not started yet-----------------------------  "
	
fi	

#v 1.1
#		line 5: second condition was added, so user be able to see logs in case of WF crashing
#		line 9: deleted titles from display
#v 1.2	
#		changed current step displaying 
#####################################################
#####################################################