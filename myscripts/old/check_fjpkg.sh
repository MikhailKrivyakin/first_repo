#!/bin/bash
#delete previos results
rm check.file
barclay='1.33.0_1'
GB='1.2007.2034_6'
Opos='2.5.4'
lockdown='1.3.23'
for till in $(cat posclients.list)
	do		
		profuse task run run-command-posclient $till 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > tmp.file
################################################## 
###################################################			barclay check
		if (($(cat tmp.file |grep "fujitsu-barclay-smartpay" |grep $barclay |wc -l) > 0 ));then 
			echo "Barclay packege on $till is OK"
		else 
			echo "fixing barclay packege on till $till"
			echo removing...
			profuse task run run-command-posclient $till 'fjpkg rm fujitsu-barclay-smartpay'
			echo ref...
			profuse task run run-command-posclient $till 'fjpkg ref'
			echo installing...
			profuse task run run-command-posclient $till 'fjpkg in fujitsu-barclay-smartpay'
			echo checking...
			profuse task run run-command-posclient $till 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat check.file |grep "fujitsu-barclay-smartpay" |grep $barclay |wc -l) -gt 0 ));then 
					echo "Barclay packege on $till was replaced to actual"
					
				else
					echo "There are some problems with Barclay packege on $till, please check manually"
				fi
		fi
################################################## 
##################################################			Gb check
		if (($(cat tmp.file |grep "fujitsu-globalblue-windows" |grep $GB |wc -l) > 0 ));then 
			echo "GlobalBlue packege on $till is OK"
		else 
			echo "fixing GlobalBlue packege on till $till"
			echo removing...
			profuse task run run-command-posclient $till 'fjpkg rm fujitsu-globalblue-windows'
			echo ref...
			profuse task run run-command-posclient $till 'fjpkg ref'
			echo installing...
			profuse task run run-command-posclient $till 'fjpkg in fujitsu-globalblue-windows'
			echo checking...
			profuse task run run-command-posclient $till 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat tmp.file |grep "fujitsu-globalblue-windows" |grep $GB |wc -l) > 0 ));then 
					echo "GlobalBlue packege on $till was replaced to actual"
					
				else
					echo "There are some problems with GlobalBlue packege on $till, please check manually"
				fi
		fi
		
################################################## 
##################################################   OPOS check
		if (($(cat tmp.file |grep "fujitsu-opos-drivers" |grep $Opos|wc -l) > 0 ));then 
			echo "Opos drivers packege on $till is OK"
		else 
			echo "fixing Opos drivers packege on till $till"
			echo removing...
			profuse task run run-command-posclient $till 'fjpkg rm fujitsu-opos-drivers'
			echo ref...
			profuse task run run-command-posclient $till 'fjpkg ref'
			echo installing...
			profuse task run run-command-posclient $till 'fjpkg in fujitsu-opos-drivers'
			echo checking...
			profuse task run run-command-posclient $till 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat tmp.file |grep "fujitsu-opos-drivers" |grep $Opos |wc -l) > 0 ));then 
					echo "Opos drivers packege on $till was replaced to actual"
					
				else
					echo "There are some problems with Opos drivers packege on $till, please check manually"
				fi
		fi
################################################## 
################################################## Lockdown check
		if (($(cat tmp.file |grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |grep $lockdown |wc -l) > 0 ));then 
			echo "Lockdown packege on $till is OK"
		else 
			echo "fixing Lockdown packege on till $till"
			echo removing...
			profuse task run run-command-posclient $till 'fjpkg rm fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809'
			echo ref...
			profuse task run run-command-posclient $till 'fjpkg ref'
			echo installing...
			profuse task run run-command-posclient $till 'fjpkg in fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809'
			echo checking...
			profuse task run run-command-posclient $till 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > check.file
				if (($(cat tmp.file |grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |grep $lockdown  |wc -l) > 0 ));then 
					echo "Lockdown packege on $till was replaced to actual"
					
				else
					echo "There are some problems with Lockdown packege on $till, please check manually"
				fi
		fi
		
done
	echo end

