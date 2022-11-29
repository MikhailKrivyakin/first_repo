#!/bin/bash

touch $1_logfile

while [ $(cat $1_logfile |grep "mark host as deployed"|wc -l ) -lt 1 ]
do 
    #variables list
        pl_pgina="[ - ]"
        pl_lockdown="[ - ]"
        pl_system_drivers="[ - ]"
        pl_specifications="[ - ]"
        prepos_opos="[ - ]"
        prepos_globalblue="[ - ]"
        db_sql="[ - ]"
        eft_ignico="[ - ]"
        eft_barclay="[ - ]"
        pos_mp="[ - ]"
        postpos_win_updates="[ - ]"
        prepl_mcafee="[ - ]"
        percents=0
    
    clear
    echo -e "\n\n ------------------------------------- Rebuild of the till $1 in progress ------------------------------------- \n\n"
    tail -n "+$(grep -a -n  "Attempting deploy of POS-client: $1" /opt/fujitsu/log/deploy.log| tail -n1 | cut -d: -f1)" /opt/fujitsu/log/deploy.log |grep $1 > $1_logfile
    
    #currentsise=$(stat -c%s $1_logfile)
    #examplesize=46188
    #percents=$(($currentsise*100/$examplesize))	
    #if block
        if [ $(cat $1_logfile|grep "=> (item=fujitsu-mcafee-endpoint-security)"|wc -l) -gt 0 ]
            then 
                prepl_mcafee="[OK]"
                percents=9
        fi
        if [ $(cat $1_logfile|grep "=> (item=fujitsu-pgina)"|wc -l) -gt 0 ]
            then 
                pl_pgina="[OK]"
                percents=18
        fi
        if [ $(cat $1_logfile|grep " => (item=fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809)"|wc -l) -gt 0 ]
            then 
                pl_lockdown="[OK]"
                percents=27
        fi
        if [ $(cat $1_logfile|grep "=> (item=fujitsu-platform-specification-windows)"|wc -l) -gt 0 ]
            then 
                pl_specifications="[OK]"
                percents=36
        fi
        if [ $(cat $1_logfile|grep " => (item=fujitsu-opos-cco)"|wc -l) -gt 0 ]
            then 
                prepos_opos="[OK]"
                percents=45
        fi
        if [ $(cat $1_logfile|grep " => (item=fujitsu-globalblue-windows)"|wc -l) -gt 0 ]
            then 
                prepos_globalblue="[OK]"
                percents=54
        fi
        if [ $(cat $1_logfile|grep "=> (item=fujitsu-ms-sql-server-express-2017)"|wc -l) -gt 0 ]
            then 
                db_sql="[OK]"
                percents=63
        fi
        if [ $(cat $1_logfile|grep "=> (item=fujitsu-ingenico-drivers)"|wc -l) -gt 0 ]
            then 
                eft_ignico="[OK]"
                percents=72
        fi
          if [ $(cat $1_logfile|grep "=> (item=fujitsu-barclay-smartpay)"|wc -l) -gt 0 ]
            then 
                eft_barclay="[OK]"
                percents=81
        fi
          if [ $(cat $1_logfile|grep "=> (item=marketplace-pos-till="|wc -l) -gt 0 ]
            then 
                pos_mp="[OK]"
                percents=90
        fi
          if [ $(cat $1_logfile|grep "=> (item=fujitsu-updates-windows-10-enterprise-2019-ltsc-1809-u2_2)"|wc -l) -gt 0 ]
            then 
                postpos_win_updates="[OK]"
                percents=100
        fi



    echo -ne "\n[ $(for (( i = 0; i < $percents; i++ ))do echo -n "="; done; ) $(for (( i = $percents; i < 100; i++ ))do echo -n "-"; done; )]($percents%)"
    #display checkpoints
        echo -e "\n\nCheckpoints:\n --------------------------------------------------------------------------\n"
        echo -e "Pre-Platfromd fjpkg: \n McAffe                    $prepl_mcafee"
        echo -e "\n --------------------------------------------------------------------------\n"
        echo -e "Platfromd fjpkg: \n Pgina                     $pl_pgina\n Lockdown                  $pl_lockdown \n Specifications            $pl_specifications "
        echo -e "\n --------------------------------------------------------------------------\n"
        echo -e "Prepos fjpkg: \n OPOS                      $prepos_opos\n Globalblue:               $prepos_globalblue"
        echo -e "\n --------------------------------------------------------------------------\n"
        echo -e "Database fjpkg: \n Ms-sql-server             $db_sql"
        echo -e "\n --------------------------------------------------------------------------\n"
        echo -e "Eft fjpkg: \n Ignico                    $eft_ignico \n Barclay                   $eft_barclay"
        echo -e "\n --------------------------------------------------------------------------\n"
        echo -e "POS fjpkg: \n MarketPlace               $pos_mp"
        echo -e "\n --------------------------------------------------------------------------\n"
        echo -e "Post-pos fjpkg: \n Windows Updates           $postpos_win_updates"
        echo -e "\n --------------------------------------------------------------------------\n"
    sleep 10
done

echo -e "\n --------------------------------------------------------------------------\n\n Rebuild of the $1 is done. Please proceed with post-rebuild steps\n\n --------------------------------------------------------------------------\n"

