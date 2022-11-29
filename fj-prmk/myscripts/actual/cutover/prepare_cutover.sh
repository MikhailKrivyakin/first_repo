#!/bin/bash
source packages_versions
. /opt/fujitsu/profuse/zonemaster/misc/lib/workflows.inc.sh

#remove previus results
{
    rm pos*.list
    rm ready_tills.list
    rm errors.list
    rm -r tills_wf/*
    rm logfile
} &>/dev/null
create_unit_lists


#create WFs for every till in list
    for till in $(cat posclients.list)
    do 
    mkdir tills_wf/wf_$till
    cp -rp sample/* tills_wf//wf_$till
    mv tills_wf/wf_$till/run-steps.sh tills_wf/wf_$till/$till.start.sh
    echo $till > tills_wf/wf_$till/posclients.list
    #change packages versions to actual
       # sed  -i "s/barclay-version/$barclay_sample/" tills_wf/wf_$till/04-check-fjpkg-posclients/script.ps1
       # sed  -i "s/gb-version/$GB_sample/" tills_wf/wf_$till/04-check-fjpkg-posclients/script.ps1
       # sed  -i "s/lockdown-version/$lockdown_sample/" tills_wf/wf_$till/04-check-fjpkg-posclients/script.ps1
       # sed  -i "s/barclay-version/$barclay_sample/" tills_wf/wf_$till/10-re-check-packages-posclients/script.ps1
       # sed  -i "s/gb-version/$GB_sample/" tills_wf/wf_$till/10-re-check-packages-posclients/script.ps1
       # sed  -i "s/lockdown-version/$lockdown_sample/" tills_wf/wf_$till/10-re-check-packages-posclients/script.ps1

    done



#sed -i "/t001/d" posclients.list
#cat posclients.list | parallel "tills_wf/wf_{}/run-steps.sh" > logfile