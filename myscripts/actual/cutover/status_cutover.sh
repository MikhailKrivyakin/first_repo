#!/bin/bash

function f_fix_lockdown
{
    if [ ! -e tills_wf/wf_$1/was_rebooted.txt ];then
        profuse task run run-command-posclient $1 "shutdown -r -t 0"    #reboot till if it wasnt rebooted yet
        echo $1 > tills_wf/wf_$1/was_rebooted.txt                       #create flag-file
        echo "Lockdown issue"
        sleep 300
        profuse task run ping-host $1 retry-until-success               #waiting for host to come back
        echo 1 |./tills_wf/wf_$1/run-steps.sh                           #re-run WF
        
    else
        echo "Lockdown issue, check manually"                           #in case if one rebooted have not solved issue
    fi

}



function f_till_status
{
    state="[Disconnected]      |"    #state by default
    percents="-"
    step_count=$(($(tills_wf/wf_$1/status.sh |wc -l)-3))
   #check if wf was started
   if [ -e tills_wf/wf_$1/out-runlog.txt ];then
        current_step_name=$(cat tills_wf/wf_$1/out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')
        dim=$((40-$(echo $current_step_name |wc -c)))
         #check if till is reacheble via profuse
        {
        if  [ $(cat tills_wf/wf_$1/01-wait-connect-posclients/out-posclients-ok.list |grep $1 |wc -l) -gt 0 ];then
            state='[Connected]         |'
        fi
        }&>/dev/null
        #check if wf completed
        if [ $(tail tills_wf/wf_$1/out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail tills_wf/wf_$1/out-runlog.txt |grep "Errors" | wc -l) -eq 0 ] ; then 
            state="Ready for testing   |"   #mark till as ready
            if [ $(cat ready_tills.list |grep $1 |wc -l) -eq 0 ];
                 then
                    echo  $1 >>ready_tills.list             
            fi
        fi
        #check if wf was stopped
        if [ -e tills_wf/wf_$1/*$current_step_name*/out-posclients-error.list ] && [ $(tail tills_wf/wf_$1/out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then                                                              
            state='Error!'			
            echo -e "$1 \n ----------------- \n" >> $1_errors.list      #print till errors
            #lockdown check
            if [ "$(tail tills_wf/wf_$1/*$current_step_name*/out-log/$1.txt |grep "ensure template for 'locked' is applied as system"|wc -l)" -gt 0 ] && [ $(echo "$current_step_name"|grep refresh |wc -l) -gt 0 ]; then 
                
                state=$(f_fix_lockdown $1)      #lockdown issue fix
            else
                tail tills_wf/wf_$1/$current_step_name/out-log/$1.txt >> $1_errors.list         
            fi
        fi
        #WinRm error check   
        if [ -e tills_wf/wf_$1/*$current_step_name*/out-log/$1.txt ];then
            time=$((`date +%s` - `date -r tills_wf/wf_$1/*$current_step_name*/out-log/$1.txt +%s`))   2>/dev/null     
        
            #check for changes in 10 minutes and if file is not OK yet				
            if [ $time -gt 600 ] && [ $(cat tills_wf/wf_$1/*$current_step_name*/out-*-ok.list|grep $1|wc -l ) -eq 0 ] ; then
                warning="Warning!"
            fi
        fi
          #till output
         if [ $(echo "$current_step_name"|grep "refresh-posclients" |wc -l) -gt 0 ];then
         {
            currentsise=$(stat -c%s tills_wf/wf_$1/*$current_step_name*/out-log/$1.txt)
            examplesize="37559"
			percents=$(($currentsise*100/$examplesize))

         }&>/dev/null
            echo -e "$1 |    $state     [$current_step_name] $(for (( i = 0; i < $dim; i++ ))do echo -n " "; done; )/[$step_count]          [$percents]%    $warning"
        else
            echo -e "$1 |    $state     [$current_step_name] $(for (( i = 0; i < $dim; i++ ))do echo -n " "; done; )/[$step_count]  $warning"
         fi
                 
            
    else    
        echo "$1 - wf has not started yet"
    fi
       
       
}


rm errors.list 2>/dev/null
touch ready_tills.list
export -f f_fix_lockdown
export -f f_till_status
echo "Here will be errors:" >errors.list


function site_status
{
   
    for site in $(cat sites.list)
    do
        echo "$site             till state                current step"
        echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
        cat posclients.list|grep $site | parallel --no-notice f_till_status {} |sort
        echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
    done
        {
        cat *_errors.list >errors.list  #gather all errors list to one
        }&>/dev/null        
        rm *_errors.list    2>/dev/null            
 
    echo "Here will be errors:"
    cat errors.list 2>/dev/null
   
}
export -f site_status

 



watch -t -n5  site_status

