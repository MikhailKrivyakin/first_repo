#!/bin/bash


export SHELL=$(type -p bash)
echo -e "\n\n Till:		|		Barclay		|		Globalblue		|		OPOS		|		Lockdown		|"
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
function check_packages {


		profuse task run run-command-posclient $1 'fjpkg pa' |grep "fujitsu-barclay-smartpay \| fujitsu-opos-drivers\|fujitsu-globalblue-windows\|fujitsu-windows-lockdown"|grep "i |" > tmp.file_$1
		barclay=$(cat tmp.file_$1 | grep barclay |cut -c 111-125 |sed ' s/ //g')
		GB=$(cat tmp.file_$1 | grep "fujitsu-globalblue-windows" |cut -c 111-125 |sed ' s/ //g')	
		Opos=$(cat tmp.file_$1 | grep "fujitsu-opos-drivers" |cut -c 111-125 |sed ' s/ //g')	
		lockdown=$(cat tmp.file_$1 | grep "fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809" |cut -c 111-125 |sed ' s/ //g')

		echo "$1   	|		$barclay	|		$GB		|		$Opos		|		$lockdown			|"
		
}
export -f check_packages


cat posclients.list |parallel --no-notice check_packages {}
echo " -----------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\n\n\n Done"
#delete  results
rm tmp.file* 2>/dev/null




