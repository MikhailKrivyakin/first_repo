#!/bin/bash


function f_get_package_state
{
display_name=$(echo $1 |cut -d '|' -f 1)
package_name=$(echo $1 |cut -d '|' -f 2)
package_percent=$(echo $1 |cut -d '|' -f 3)
package_state="[ - ]"
dim=$((35-$(echo $display_name| wc -c)))
    if [ $(cat ${till_number}_logfile|grep -a "=> (item=$package_name)*"|wc -l) -gt 0 ]
            then 
                package_state="[OK]"
                percents=$package_percent
    fi
    echo -e "   $display_name $(for (( i = 0; i < $dim; i++ ))do echo -n " "; done; )$package_state"


}
export -f f_get_package_state
function f_main
{
#check of the platfrom version (05.04.2022). Required because different pl versions have different playbooks
[ ! -f $1_pl_version ] && profuse profile site show $(echo $1 |cut -c 1-6) |grep PLATFORM |cut -d '-' -f5> $1_pl_version && pl_version=$(cat $1_pl_version) || pl_version=$(cat $1_pl_version)
touch $1_logfile
till_number=$(echo $1)
percents=0
    #clear
    echo -e "\n\n ------------------------------------- Rebuild of the till $1 in progress. Platform version determined:: $pl_version ------------------------------------- \n"
    tail -n "+$(grep -a -n  "Attempting deploy of POS-client: $1" /opt/fujitsu/log/deploy.log| tail -n1 | cut -d: -f1)" /opt/fujitsu/log/deploy.log |grep $1 > $1_logfile
    #declare fjpkg repos arrays
    Pre_Platform=("McAffee|fujitsu-mcafee-endpoint-security|9")
    Platform=("Pgina|fujitsu-pgina|18" "Lockdown|fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809|27" "Specifications|fujitsu-platform-specification-windows|36")
    Pre_pos=("OPOS|fujitsu-opos-cco|45" "Globalblue|fujitsu-globalblue-windows|54")
    Database=("MySq|fujitsu-ms-sql-server-express-2017|63")
    Eft=("Igenico|fujitsu-ingenico-drivers|72" "Barclay|fujitsu-barclay-smartpay|81")
    POS=("MarketPlace|marketplace-pos-till=|90")
    #Post_POS=("WinUpdates|fujitsu-updates-windows-10-enterprise-2019-ltsc-1809-u2_2|99")
    case $pl_version in
       "4.6.3")
          Post_POS=("WinUpdates|fujitsu-updates-windows-10-enterprise-2019-ltsc-1809-u2_2|99")
           ;;

        "4.6.8")
            Post_POS=("FirewallRules|fujitsu-firewall-rules-windows|93" "WinUpdate1|windows10.0-kb5008602-x64_5535dd10ef8d98b2acede815d6b7fa002f306c33.msu|96" "WinUpdate1|sqlserver2017-kb5006944-x64_1109176cec3724feb7e21b6e6804b0876229c7c9.exe|98")
        ;;
        *)
             Post_POS=("WinUpdates|fujitsu-updates-windows-10-enterprise-2019-ltsc-1809-u2_2|99") #deafult packege set
        ;;
    esac
    #declare name array
    list=("Pre_Platform" "Platform" "Pre_pos" "Database" "Eft" "POS" "Post_POS")
    for package_list in ${list[@]}; do 
    tmp="${package_list}[@]" 
        echo -e "${package_list} fjpkg:"
    
        for package in "${!tmp}"; do
         f_get_package_state $package 
        done
    echo " ----------------------------------"
    done 
   
    if [ $(grep -c "mark host as deployed" $1_logfile) -gt 0 ]; then
    
        echo -e " --------------------------------------------------------------------------------------------------------------"               
        echo "                                      Rebuild of the till $1 ended"
        echo -e " --------------------------------------------------------------------------------------------------------------"
        percents=100

    fi
    echo -ne "\n[ $(for (( i = 0; i < $percents; i++ ))do echo -n "="; done; ) $(for (( i = $percents; i < 100; i++ ))do echo -n "-"; done; )]($percents%)\n\n"
    sleep 5
#done
#echo "Rebuild of the till $1 ended"
}

export -f f_main
watch -n5 -t f_main $1