#!/bin/bash

echo "Site:             Current step:"
echo " --------------------------------------------------------------------"
for site in $(cat sites.list)
do
    if [ $(tail pre-syncs/wf_$site/out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail pre-syncs/wf_$site/out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then
                current_step_name="Workflow finished"
    elif [ $(tail pre-syncs/wf_$site/out-runlog.txt |grep "Aborting" | wc -l) -gt 0 ]; then                                                               #check if wf was stopped
                current_step_name='Workflow stopped. Check Errors'			
        else
    current_step_name=$(cat pre-syncs/wf_$site/out-runlog.txt | grep "RUNNING STEP"| tail -1| tr -d '*** RUNNING STEP:')
    fi
    echo -e "$site        $current_step_name"
    echo " --------------------------------------------------------------------"
done