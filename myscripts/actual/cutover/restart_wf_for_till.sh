#!/bin/bash





echo -e 'Restarting WF for specified tills'
echo " -----------------------"
for till in "$@"
do

    if [[ $(echo $TERM | grep -c "screen") -eq 0 ]] > /dev/null;then
        echo -e "Warning\n Workflows should be runned within screen session! \n Use screen -S YourSessionName to enter screen session. \n P.S. Do not forget to exit your session after end of all activities "
        echo " --------------------------------"
        break
    fi
  echo 1|  ./tills_wf/wf_$till/$till.start.sh >> logfile &
    echo "$till | --- restarted"
    sleep 5

done

