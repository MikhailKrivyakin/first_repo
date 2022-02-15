
#!/bin/bash
. /opt/fujitsu/profuse/zonemaster/misc/lib/workflows.inc.sh

# We need to do a full refresh since we might have new platform repoclients too, and those are not possible
# to refresh using ansible tags (-t) in the current profuse version.
#
# This means we leave the below "restricted" refresh commented out and do a full refresh.
#
#export ANSIBLE_OPTIONS="-t always,refresh_repos,fjpkglist_pos"

ip=$(profuse unit show |grep $(cat ../posclients.list) |cut -c 49-60)

#cycle for save some ZM resources and not to ping via PROFUSE, untill (DUP!) packages is absent
while :
do
    result=$(ping -c 5 -W 5 $ip)
    if [ $? -eq 0 ];then
		state="UP"
	fi
	if [[ $(echo $state) == "UP"  &&  $(echo $result | grep DUP |wc -l) -gt 0 ]]; then
          break           #till is connected and booted. Starting ping via profuse
    fi
    sleep 120
done


run_task ping-host retry-until-success
