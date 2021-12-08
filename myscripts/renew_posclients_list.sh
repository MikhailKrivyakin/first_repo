#!/bin/bash
source ping_sites.sh
touch ready_tills.list
for site in $(cat sites.list)
    do
        profuse unit show $site| grep Till > tills_IP.list
    done
echo ''
date
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
cat posclients.list >> ready_tills.list
rm posclients.list 2>/dev/null
for till in $(cat tills_IP.list | parallel --no-notice ping_till {} |grep Toshiba |cut -c 1-11)
do
    if [[ $(cat ready_tills.list |grep $till|wc -l) -eq 0 ]]; then
        echo $till >> posclients.list
    fi
done
echo "Ready tills"
cat ready_tills.list
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo "Tills to be refreshed: "
cat posclients.list
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo Done
rm tills_IP.list; #remove trash