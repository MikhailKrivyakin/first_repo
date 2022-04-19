#!/bin/bash

rm error.list
function f_check_amt
{
    profuse task run amt-powerinfo-posclient $1 >${1}_result
    if  grep Success ${1}_result>/dev/null; then
        
        rm $1_result
    else
        echo $1>>error.list
    fi
    

}

export -f f_check_amt

cat tills.list |parallel --no-notice f_check_amt {}
echo -e "\nThose tills has incorrect AMT settings, check their log-files:"
echo " --------------------------------------------------------------"
cat error.list
echo " --------------------------------------------------------------"
echo done