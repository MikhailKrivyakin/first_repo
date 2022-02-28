#!/bin/bash

function f_run_upgrade
{
    MPProfile=$(cat profiles_new.list|grep MARKETPLACE)
    if [ "$MPProfile" != "" ]; then
        MPTag=$(profuse profile show tags $MPProfile|grep posclient)
        MPVer=${MPTag##*=}
    else
        echo "This workflow is for Marketplace only and no such profile is found. Exiting script"
    exit 1
    fi

    export MPVer

    02-prechecks/run-steps.sh && 03-update-profiles-site/run-steps.sh && 04-upgrade-posservers/run-steps.sh && 05-upgrade-till-1/run-steps.sh


}

if [ -e sites.list ];then 
    live_stores=()  #list of prod.stores
{
        for site in $(cat sites.list) 
        do
            if [ $(profuse profile site show $site |grep "STORE-IS-LIVE" |wc -l) -gt 0 ];then #looking for live profile for store in profuse
            {
                live_stores+=($(echo -e "$site\n"))
            }
            fi
        done
    if [ ${#live_stores[@]} -gt 0 ];then    #if live store were found  write warning and ask for confirmation
    {
        echo " -------------------------------------"
        echo -e "WARNING! \nYou are are going to run upgrade and some of the stores in list are live ones!\n \nThis stores are live ones: ${live_stores[@]}\n\nIf you still want to run, please write IAMSURE\n "
        read decision
        case $decision in
                    "IAMSURE")                                  #if IAMSURE than run upgrade
                    echo "Running upgrade"
                    echo " -------------------------------------"
                    f_run_upgrade
                    ;;
                    *)  
                    echo "Aborting."                               # any different question leads to abort
                    echo " -------------------------------------"
                    exit
                    ;;
        esac

    }
    else                                                            #if live stores weren`t found start upgade immidiatly`
    {
        echo "Running upgrade"
        echo " -------------------------------------"
        f_run_upgrade

    }
    fi
}
else                                                                    #if sites.list not found
{
    echo " -------------------------------------"
    echo "sites.list not found. Aborting"
    echo " -------------------------------------"

}
fi


