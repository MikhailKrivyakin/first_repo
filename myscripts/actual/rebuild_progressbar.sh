#!/bin/bash

touch $1_logfile

while [ $(cat $1_logfile |grep "mark host as deployed"|wc -l ) -lt 1 ]
do 
    clear
    echo -e "\n\n ------------------------------------- Rebuild of the till $1 in progress ------------------------------------- \n\n"
    tail -n "+$(grep -n 'Attempting deploy of POS-client:*' /opt/fujitsu/log/deploy.log| tail -n1 | cut -d: -f1)" /opt/fujitsu/log/deploy.log |grep $1 > $1_logfile
    currentsise=$(stat -c%s $1_logfile)
    examplesize=46188
    percents=$(($currentsise*100/$examplesize))	
    echo -ne "\n[ $(for (( i = 0; i < $percents; i++ ))do echo -n "="; done; ) $(for (( i = $percents; i < 100; i++ ))do echo -n "-"; done; )]($percents%)"
    sleep 30
done

echo -e "\n --------------------------------------------------------------------------\n\n Rebuild of the $1 is done. Please proceed with pos-rebuild steps\n\n --------------------------------------------------------------------------\n"

