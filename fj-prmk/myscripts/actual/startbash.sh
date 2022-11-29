#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "No argument or more than 1."
exit
fi
cp bashedscript.ps1 ${1}.ps1
sed -i "s/till_number_forrepl/$1/" ./${1}.ps1
echo -e "\n Running script on $1...\n"
echo " -----------------------------"
profuse task run run-script-posserver $(echo $1 | cut -c 1-6)s001 "/root/scripts/rebuildstatus/${1}.ps1" > $1_log
cat $1_log |grep -A4 "show stdout output" $1_log |egrep -v "result.stdout_lines|ok|TASK"
echo " -----------------------------"
echo Done
rm $1_log
rm ${1}.ps1
#sed -i "s/$1/till_number_forrepl/" ./bashedscript.ps1
