#!/bin/bash
export SHELL=$(type -p bash)
function getserial
{

    serialnumber=$(profuse task run run-command-posclient $1 '$serial=GCI c:/BarclayCard/SolveConnect/logs/ -name SolveConnectTerminal* |select-object -last 1 |get-content| Select-String -Pattern "Serial number"|select-object -last 1 | out-string; -join ($serial.ToCharArray() |Select-Object -last 30)'|head -n4 |tail -n1)
    echo "$1:  $serialnumber"

}
export -f getserial
profuse unit show $1| grep Till|cut -c 1-10 | parallel --no-notice getserial {} |sort