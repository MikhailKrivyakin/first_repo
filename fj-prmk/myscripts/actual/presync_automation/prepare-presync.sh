#!/bin/bash
mkdir pre-syncs
for site in $(cat sites.list) 
do
    
    mkdir pre-syncs/wf_$site
    cp -rp 01-prepare-daytime/* pre-syncs/wf_$site
    rm pre-syncs/wf_$site/pos*
    echo $site > pre-syncs/wf_$site/sites.list
    cat rollback_clients.list |grep $site > pre-syncs/wf_$site/posclients.list
    cat posservers.list |grep $site > pre-syncs/wf_$site/posservers.list
    cat profiles_new.list > pre-syncs/wf_$site/profiles_new.list

done