#!/bin/bash

function f_check_pl_till
{
        echo -n "$1 "> $1.result
        echo  $(profuse task run run-script-posclient $1 '/home/rusmik/PLcheck/plcheck.ps1' |grep Version |cut -c 18-22 ) >> $1.result
        cat $1.result >>result_$2.csv
        rm $1.result 


}

export -f f_check_pl_till

for site in $(cat st.list)
do
profuse unit show $site |grep Till |cut -c 1-10 > tills_$site.list
echo -e "$site \n" > result_$site.csv
cat tills_$site.list | parallel --no-notice f_check_pl_till {} $site
    #for till in $(cat tills_$site.list)
    #do
     #   echo -n "$till "> $till.result
      #  echo  $(profuse task run run-script-posclient $till '/home/rusmik/PLcheck/plcheck.ps1' |grep Version |cut -c 18-22) >> $till.result
       # cat $till.result >>result_$site.csv
        #rm $till.result 
   # done


done