#!/bin/bash
#vars
    current_step_number=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1|cut -c 19-20)
    current_step_name=$(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')
    total_steps=$(($(./status.sh |wc -l)-3))	# find total step number, using ./status output
    title_chars_number=$(($(cat out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:'|wc -m)/2))



#functions
    function determinate_unit_type                                                                                       #determinate unit, which currents step is working with
    {
        
        if [[ $(echo $1) == *"servers"* ]];then
            unit_type="server"
        elif [[ $(echo $1) == *"clients"* ]];then
            unit_type="client"
        elif [[ $(echo $1) == *"posadmins"* ]];then
            unit_type="posadmin"	
        elif [[ $(echo -e $1) == *"drop"[0-9]* ]];then
            unit_type="$(echo $1 |tail -c6)"
        elif [[ $(echo $1) == *"sites"  ||  $(echo $1) == *"site" ]] ;then
            unit_type="site"
        fi	
        echo $unit_type
        
    }

    function counter                                                                                                     #count unit per steps (OK/all/error)
    {

        totalOK=0
        total=0
        totalEr=0

        
                echo -e '\nProgress per site: \n ----------------------------------------------------\nSite		OK/ALL			Failed'     #counter title
        #start cycle for each store in sites.list			
        for site in $(cat sites.list)
            do	
            {
                count=$(cat *$unit_type*.list | grep $site | grep -vE "t5|t6"| wc -l)                                                         # count in common per store
                ok_count=$(cat *$current_step_name*/out-*-ok.list | grep $site |wc -l)                                      #counting OK units
                }&>/dev/null
                error_count=0
                #checking if any failed unit is exist
                if [ -e *$current_step_number*/out-*-error.list ];
                then 		
                #counting error tills
                            
                    error_count=$(($(cat *$current_step_number*/out-*-error.list |grep $site |grep -vE "t5|t6"| wc -l)))                     #counting error units
                    totalEr=$(($totalEr+$error_count))
                                    
                fi	
                            
                echo "$site		$ok_count / $count			$error_count"                                                   #print output per store
                totalOK=$(($totalOK+$ok_count))
                total=$(($total+$count))
            done
                echo " ----------------------------------------------------"
                echo  Total"		"$totalOK / $total"			"$totalEr                                                   #print output in total
    }



    function error_parser                                                                                              #parser code
    {
        count_per_rows=0
            if [ -e *$current_step_number*/out-*-error.list ]; then
                #title of result file
                echo -e " ----------------------------------------------------------------------\nThose units is unreacheble:" >> error_log 
                
                #checking out error-list and their logs, puting unreacheble and other errors to separate files
                for unit in $(cat *$current_step_name*/out-*-error.list)
                    do
                    if  [[ $(echo $unit |grep -vE "t5|t6"|wc -l) -gt 0  ]]; then
                        # if rows count with "Unreachable > 0 
                    if [ "$(tail *$current_step_number*/out-log/$unit.txt |grep "Failed to connect to the host via ssh:"|wc -l)" -gt 0 ]; then           
                        
                            echo -n "$unit      |" >> unreacheable.list
                            count_per_rows=$(($count_per_rows+1))                       
                                            
                    else 
                        echo -e "\t_______ failed __________\t\n" >> other_errors #else it`s some kind of other error and needs invistigation
                        echo " $unit :" >> other_errors
                        tail *$current_step_number*/out-log/$unit.txt >>other_errors
                            
                    fi		
                        if [ $count_per_rows -gt 3 ]; then
                            echo  -e " $unit" >> unreacheable.list 
                            count_per_rows=0 
                        fi
                    fi
                    done
            # combining files to error_log	
                {
                cat unreacheable.list | grep -vE "t5|t6"  >> error_log  #|tr '\n' ':'
                }&>/dev/null
                echo '' >> error_log
                if [ -e other_errors ]; then
                    echo -e '\n ---------------------------------------------------------------------- \n******************************************\n\nOther failed tills: \n ' >> error_log
                    cat other_errors >> error_log
                    rm other_errors
                fi
                #display result
                cat error_log
                rm error_log 2>/dev/null 
                rm unreacheable.list 2>/dev/null
            else
                echo -e "There are no errors in your workflow...yet\n"
            fi	


    }





#check if WF was running

    if [ -e out-runlog.txt ]; then
        #_______________________________________________________________________________
        #check if WF was completed
        if [ $(tail out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then
            echo -e "   										WF monitoring v2.5 by Mikhail Krivyakin\n"
            echo -e "\n ------------------------------ Workflow finished, hope you have enjoyed it -----------------------------  "
        else

            # title if it runned
            echo -e "   									WF monitoring v2.5 by Mikhail Krivyakin  "
            echo -e " $(for (( i = 0; i < 37; i++ ))do echo -n "-"; done; ) Current step is: $current_step_number / $total_steps. $(for (( i = 63; i < 101; i++ ))do echo -n "-"; done; )\n"
                     echo -e " $(for (( i = 0; i < $(( 50-$title_chars_number)); i++ ))do echo -n "-"; done; ) $current_step_name $(for (( i = $(( 50+$title_chars_number)); i < 101; i++ ))do echo -n "-"; done; )"
            

             if [ $(tail out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then                                                               #check if wf was stopped
                echo -e 'Workflow was stopped. Check Errors'			
            fi
            unit_type=$(determinate_unit_type $current_step_name)
            counter $unit_type
            echo -e "\n\n"
            error_parser $current_step_number
            echo -e "\n\n"
    fi

    #_______________________________________________________________________________
#if no outputs then message
else
	
	echo -e "   							$1		WF monitoring v2.5 by Mikhail Krivyakin\n -------------------------------- Upgrade has not started yet -----------------------------  "
	
fi	