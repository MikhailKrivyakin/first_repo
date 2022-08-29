#!/bin/bash
failare_till=$(echo $1)
echo " ----------------------------------------------------------"
if [[ "$1" == *t001 ]]; then
    echo "Failare till is the first till in the store."
    good_number=2
    good_till=${failare_till:0:9}$good_number
    echo "Files will be taken from the till $good_till"
    echo
else
    echo "Failare till is the not first till in the store."
    good_number=1
    good_till=${failare_till:0:9}$good_number
    echo "Files will be taken from the till $good_till"
    echo
fi
echo "Creating temp directory for files..."
    mkdir ${1}_mp_fix
    sleep 1
echo "Copying files from the good till..."
    /opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $good_till -m fetch -a "flat=yes src='c:/program files/Fujitsu/bin/Fujitsu.Utilities.MessageBus.ServiceHost.Core.config'  dest=$(pwd)/${1}_mp_fix/" >> $(pwd)/${1}_mp_fix/logfile
    /opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $good_till -m fetch -a "flat=yes src='c:/program files/Fujitsu/bin/Fujitsu.Utilities.MessageBus.ServiceHost.POS.config'  dest=$(pwd)/${1}_mp_fix/" >> $(pwd)/${1}_mp_fix/logfile

echo "Removing files from $1..."
    profuse task run run-command-posclient $1 'rm "c:/program files/Fujitsu/bin/Fujitsu.Utilities.MessageBus.ServiceHost.Core.config";rm "c:/program files/Fujitsu/bin/Fujitsu.Utilities.MessageBus.ServiceHost.POS.config"' >> $(pwd)/${1}_mp_fix/logfile

echo "Copying good files to the failare till..."
    /opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a "src=$(pwd)/${1}_mp_fix/Fujitsu.Utilities.MessageBus.ServiceHost.POS.config dest='c:/program files/Fujitsu/bin/'" >> $(pwd)/${1}_mp_fix/logfile
    /opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a "src=$(pwd)/${1}_mp_fix/Fujitsu.Utilities.MessageBus.ServiceHost.Core.config dest='c:/program files/Fujitsu/bin/'" >> $(pwd)/${1}_mp_fix/logfile

echo "Rebooting the $1...."
    profuse task run run-command-posclient $1 'shutdown -r -t 0'

echo " ----------------------------------------------------------"
echo -e "Fix is over.\nIf everything is OK after reboot, please perfrom this command to clean the trash:\n rm -r $(pwd)/${1}_mp_fix/"