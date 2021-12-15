#!/bin/bash

function f_kill_all
{
    cat posclients.list | parallel --no-notice "pkill {}.start"

}

case $1 in
    "all")
        f_kill_all
        echo "All Wfs for tills in poslients list has beenn killed. You can check by 'ps -all'"
        ;;
    *)
        
        pkill $1.start
        echo "WF for till $1 has been killed. You can check by 'ps -all'"
esac