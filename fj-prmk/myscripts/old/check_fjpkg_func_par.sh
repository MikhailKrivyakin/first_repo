#!/bin/bash
#delete previos results
rm check.file
export SHELL=$(type -p bash)
function check_packages {
barclay='1.33.0_1'	#barclay package version
GB='1.2007.2034_6'	#globalblue package version
Opos='2.5.4'		#Opos drivers package version
lockdown='1.3.23' 	#lockdown package version
echo " ---------------------------------- $1  ---------------------------------- "
		profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > tmp.file_$1
################################################## 
###################################################			barclay check
		if (($(cat tmp.file_$1 |grep "fujitsu-barclay-smartpay" |grep $barclay |wc -l) > 0 ));then 
			echo "Barclay package on $1  is OK"
		else 
			echo -e " === FIXING barclay package on till $1\n "
			echo removing...
			#profuse task run run-command-posclient $1  'fjpkg rm fujitsu-barclay-smartpay'>/dev/null
			echo ref...
			#profuse task run run-command-posclient $1  'fjpkg ref'>/dev/null
			echo installing...
			#profuse task run run-command-posclient $1  'fjpkg in fujitsu-barclay-smartpay'>/dev/null
			echo checking...
			#profuse task run run-command-posclient $1  'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown" |grep "i |" > check.file_$1
				if (($(cat check.file_$1 |grep "fujitsu-barclay-smartpay" |grep $barclay |wc -l) > 0 ));then 
					echo "\nBarclay package on $1  was replaced to actual"
					
				else
					echo -e "\nThere are some problems with Barclay package on $1 , please check manually\n *****************************************************************************  \n "
				fi
		fi
################################################## 
##################################################			Gb check
		if (($(cat tmp.file_$1 |grep "fujitsu-globalblue-windows" |grep $GB |wc -l) > 0 ));then 
			echo "GlobalBlue package on $1 is OK"
		else 
			echo -e " === FIXING GlobalBlue package on till $1\n"
			echo removing...
			#profuse task run run-command-posclient $1 'fjpkg rm fujitsu-globalblue-windows'>/dev/null
			echo ref...
			#profuse task run run-command-posclient $1 'fjpkg ref'>/dev/null
			echo installing...
			#profuse task run run-command-posclient $1 'fjpkg in fujitsu-globalblue-windows'>/dev/null
			echo checking...
			#profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file_$1
				if (($(cat check.file_$1 |grep "fujitsu-globalblue-windows" |grep $GB |wc -l) > 0 ));then 
					echo "\nGlobalBlue package on $1 was replaced to actual"
					
				else
				echo "\nThere are some problems with GlobalBlue package on $1, please check manually\n *****************************************************************************  \n"
			fi
		fi
		
################################################## 
##################################################   OPOS check
		if (($(cat tmp.file_$1 |grep "fujitsu-opos-drivers" |grep $Opos|wc -l) > 0 ));then 
			echo -e "Opos drivers package on $1 is OK"
		else 
			echo -e " === FIXING Opos drivers package on till $1\n"
			echo removing...
			#profuse task run run-command-posclient $1 'fjpkg rm fujitsu-opos-drivers'>/dev/null
			echo ref...
			#profuse task run run-command-posclient $1 'fjpkg ref'>/dev/null
			echo installing...
			#profuse task run run-command-posclient $1 'fjpkg in fujitsu-opos-drivers'>/dev/null
			echo checking...
			#profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file_$1
				if (($(cat check.file_$1 |grep "fujitsu-opos-drivers" |grep $Opos |wc -l) > 0 ));then 
					echo "\nOpos drivers package on $1 was replaced to actual"
					
				else
					echo "\nThere are some problems with Opos drivers package on $1, please check manually\n ***************************************************************************** \n"
				fi
		fi
################################################## 
################################################## Lockdown check
		if (($(cat tmp.file_$1 |grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |grep $lockdown |wc -l) > 0 ));then 
			echo "Lockdown package on $1 is OK"
		else 
			echo -e " === FIXING Lockdown package on till $1\n"
			echo removing...
			#profuse task run run-command-posclient $1 'fjpkg rm fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809'>/dev/null
			echo ref...
			#profuse task run run-command-posclient $1 'fjpkg ref'>/dev/null
			echo installing...
			#profuse task run run-command-posclient $1 'fjpkg in fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809'>/dev/null
			echo checking...
			#profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file_$1
				if (($(cat check.file_$1 |grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |grep $lockdown  |wc -l) > 0 ));then 
					echo "\nLockdown package on $1 was replaced to actual"
					
				else
					echo "\nThere are some problems with Lockdown package on $1, please check manually\n *****************************************************************************  \n"
				fi
		fi
}
export -f check_packages


cat posclients.list |parallel check_packages {}
#rm check.file*
rm tmp.file*
#parallel -a posclients.list check_packages {}



