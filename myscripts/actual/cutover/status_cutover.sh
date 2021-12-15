#!/bin/bash

function f_fix_lockdown
{
    if [ ! -e tills_wf/wf_$1/was_rebooted.txt ];then
        profuse task run run-command-posclient $1 "shutdown -r -t 0"    #reboot till if it wasnt rebooted yet
        echo $1 > tills_wf/wf_$1/was_rebooted.txt                       #create flag-file
        profuse task run ping-host $1 retry-until-success               #waiting for host to come back
        echo 1 |./tills_wf/wf_$1/run-steps.sh                           #re-run WF
        echo "Lockdown issue"
    else
        echo "Lockdown issue, check manually"                           #in case if one rebooted have not solved issue
    fi

}

function f_till_status
{
    state="Disconnected"    #state by default
    
   #check if wf was started
   if [ -e tills_wf/wf_$1/out-runlog.txt ];then
        current_step_name=$(cat tills_wf/wf_$1/out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')
         #check if till is reacheble via profuse
        if  [ $(cat tills_wf/wf_$1/01-wait-connect-posclients/out-posclients-ok.list |grep $1 |wc -l) -gt 0 ];then
            state='Connected'
        fi
        #check if wf completed
        if [ $(tail tills_wf/wf_$1/out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail tills_wf/wf_$1/out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then 
            state="Ready for testing"
            echo $1 >> ready_tills.list             #mark till as ready
        fi
        #check if wf was stopped
        if [ $(tail tills_wf/wf_$1/out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then                                                              
            state='Error!'			
            echo -e "$1 \n ----------------- \n" >> $1_errors.list      #print till errors
            #lockdown check
        if [ "$(tail tills_wf/wf_$1/*$current_step_number*/out-log/$1.txt |grep "ensure template for 'locked' is applied as system"|wc -l)" -gt 0 ] && [ $(echo "$current_step_name"|grep refresh |wc -l) -gt 0 ]; then 
            
            state=$(f_fix_lockdown $1)      #lockdown issue fix
        else
            tail tills_wf/wf_$1/$current_step_name/out-log/$1.txt >> $1_errors.list         
        fi
        fi
         #output
         echo -e "$1     [$state]     [$current_step_name]/8"    #till output   
    else    
        echo "$1 - wf has not started yet"
    fi
       
       
}


rm errors.list 2>/dev/null
touch ready_tills.list
export -f f_till_status

echo "Here will be errors:" >errors.list


while [ $(cat posclients.list |wc -l) -ne $(cat ready_tills.list |wc -l) ]
do
    clear
        for site in $(cat sites.list)
        do
        echo $site
        echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
        cat posclients.list|grep $site | parallel f_till_status {} |sort
        echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
        done
        {
        cat *_errors.list >errors.list  #gather all errors list to one
        cat errors.list                 #read common error list
        rm *_errors.list                #remove trash
        } &>/dev/null
    sleep 5
done
echo "All till are ready for tests. Please check versions of critical packeges using ./fjpkg_check.sh and inform change manager."


