#!/bin/bash
if [ "$#" -eq 0 ]; then
    echo "You should specify till name fro using this script"
    exit
fi

echo " ----------------------------"
echo -e " Executing script for MP unistalation....\n \n "
source=$(pwd)/reinstal_mp.ps1
profuse task run run-script-posclient $1 "$source"
echo -e " \n \n \n ----------------------------"
echo "Refresh of unit $1 will start at 30 sec"
for (( i=1;i<31;i++ ))
do
    echo -n $i..
    sleep 1
done
echo " ----------------------------"
echo -e "\n \nStarting refresh of unit $1"
echo " ----------------------------"
sleep 2
profuse task run refresh-posclient $1
source2=$(pwd)/disable_tlsv1.ps1
echo " ----------------------------"
echo -e "\n \n \n  If refresh was succesfull - perform command:  profuse task run run-script-posclient $1 '$source2'\n And reboot posclient usning command: profuse task run run-command-posclient $1 'shutdown -r -t 0' "
