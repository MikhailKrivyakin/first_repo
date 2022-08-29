#!/bin/bash



if [[ $(echo $TERM | grep -c "screen") -eq 0 ]]  > /dev/null;then
        echo " --------------------------------"
        echo -e "Warning\n Workflows should be runned within screen session! \n Use screen -S YourSessionName to enter screen session. \n P.S. Do not forget to exit your session after end of all activities "
        echo " --------------------------------"
else 
        cat posclients.list | grep "t001" | parallel --no-notice "tills_wf/wf_{}/{}.start.sh"  > logfile &
        echo -e 'Staring WFs for 1st tills in list. \n All logs will be printed in logfile'
fi

    