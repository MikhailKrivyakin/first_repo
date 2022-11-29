#!/bin/bash





echo -e 'Staring WFs from tills_wf/ directory \n All logs will be printed in logfile'
echo " -----------------------"
for till in $(cat posclients.list | sed "/t001/d")
do
    
    if [[ $(echo $TERM | grep -c "screen") -eq 0 ]] > /dev/null;then
        echo -e "Warning\n Workflows should be runned within screen session! \n Use screen -S YourSessionName to enter screen session. \n P.S. Do not forget to exit your session after end of all activities "
        echo " --------------------------------"
        break
    fi
    ./tills_wf/wf_$till/$till.start.sh >> logfile &
    echo "$till | --- started"
    sleep 5

done

#cat posclients.list | sed "/t001/d" | parallel --no-notice "tills_wf/wf_{}/{}.start.sh"  > logfile &