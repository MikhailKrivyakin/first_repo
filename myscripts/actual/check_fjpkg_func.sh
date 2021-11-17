#!/bin/bash
#delete previos results
rm check.file
barclay='1.33.0_1'
GB='1.2007.2034_6'
Opos='2.5.4'
lockdown='1.3.23'

function check_packages {
echo " ---------------------------------- $1  ---------------------------------- "
		profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > tmp.file
################################################## 
###################################################			barclay check
		if (($(cat tmp.file |grep "fujitsu-barclay-smartpay" |grep $barclay |wc -l) > 0 ));then 
			echo "Barclay package on $1  is OK"
		else 
			echo "fixing barclay package on till $1 "
			echo removing...
			profuse task run run-command-posclient $1  'fjpkg rm fujitsu-barclay-smartpay' >/dev/null
			echo ref...
			profuse task run run-command-posclient $1  'fjpkg ref'>/dev/null
			echo installing...
			profuse task run run-command-posclient $1  'fjpkg in fujitsu-barclay-smartpay'>/dev/null
			echo checking...
			profuse task run run-command-posclient $1  'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat check.file |grep "fujitsu-barclay-smartpay" |grep $barclay |wc -l) > 0 ));then 
					echo "Barclay package on $1  was replaced to actual"
					
				else
					echo "There are some problems with Barclay package on $1 , please check manually"
				fi
		fi
################################################## 
##################################################			Gb check
		if (($(cat tmp.file |grep "fujitsu-globalblue-windows" |grep $GB |wc -l) > 0 ));then 
			echo "GlobalBlue package on $1 is OK"
		else 
			echo "fixing GlobalBlue package on till $1"
			echo removing...
			profuse task run run-command-posclient $1 'fjpkg rm fujitsu-globalblue-windows'>/dev/null
			echo ref...
			profuse task run run-command-posclient $1 'fjpkg ref'
			echo installing...
			profuse task run run-command-posclient $1 'fjpkg in fujitsu-globalblue-windows'>/dev/null
			echo checking...
			profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat tmp.file |grep "fujitsu-globalblue-windows" |grep $GB |wc -l) > 0 ));then 
					echo "GlobalBlue package on $1 was replaced to actual"
					
				else
					echo "There are some problems with GlobalBlue package on $1, please check manually"
				fi
		fi
		
################################################## 
##################################################   OPOS check
		if (($(cat tmp.file |grep "fujitsu-opos-drivers" |grep $Opos|wc -l) > 0 ));then 
			echo "Opos drivers package on $1 is OK"
		else 
			echo "fixing Opos drivers package on till $1"
			echo removing...
			profuse task run run-command-posclient $1 'fjpkg rm fujitsu-opos-drivers'>/dev/null
			echo ref...
			profuse task run run-command-posclient $1 'fjpkg ref'>/dev/null
			echo installing...
			profuse task run run-command-posclient $1 'fjpkg in fujitsu-opos-drivers'>/dev/null
			echo checking...
			profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat tmp.file |grep "fujitsu-opos-drivers" |grep $Opos |wc -l) > 0 ));then 
					echo "Opos drivers package on $1 was replaced to actual"
					
				else
					echo "There are some problems with Opos drivers package on $1, please check manually"
				fi
		fi
################################################## 
################################################## Lockdown check
		if (($(cat tmp.file |grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |grep $lockdown |wc -l) > 0 ));then 
			echo "Lockdown package on $1 is OK"
		else 
			echo "fixing Lockdown package on till $1"
			echo removing...
			profuse task run run-command-posclient $1 'fjpkg rm fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809'>/dev/null
			echo ref...
			profuse task run run-command-posclient $1 'fjpkg ref'>/dev/null
			echo installing...
			profuse task run run-command-posclient $1 'fjpkg in fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809'>/dev/null
			echo checking...
			profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat tmp.file |grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |grep $lockdown  |wc -l) > 0 ));then 
					echo -e "\nLockdown package on $1 was replaced to actual"
					
				else
					echo -e "\nThere are some problems with Lockdown package on $1, please check manually"
				fi
		fi
}

for till in $(cat posclients.list)
do
	check_packages $till
	
done

	echo end

