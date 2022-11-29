#!/bin/bash

export SHELL=$(type -p bash)
echo checking...
function check_svs {

		#checking every till in list for connection		
		profuse task run run-command-posclient $1 'Test-NetConnection 10.4.1.251 -Port 10113' > result_$1.tmp
		
		# if output has Fale in it than we try to create new rules and check again		
		if (( $(cat result_$1.tmp |grep False |wc -l) > 0 )); then
		    profuse task run run-command-posclient $1 'New-NetFirewallRule -Name "Allow SVS" -Description "Allow SVS" -DisplayName "Allow SVS" -Enabled:True -Profile Public -Direction Outbound -Action Allow -Protocol TCP -RemoteAddress @("10.4.1.251","10.4.2.251") -RemotePort 10113' >> error_svs_$1.log
			
			#check again
			profuse task run run-command-posclient $1 'Test-NetConnection 10.4.1.251 -Port 10113' > result_$1.tmp
			#if problem persist then inform user	
			if (( $(cat result_$1.tmp |grep False |wc -l) > 0 )); then
					echo "There are some problems with adding firewall rules to the $1 . Please chek manualy in the error_svs_$1.log" 
			else
			#if OK - than inform user and delete profuse logs
					echo "Rules for SVS connection  were added to the $1"
					rm error_svs_$1.log
			fi
		else 
		#if OK than inform user
			echo "$1 has correct firewall rules for SVS connection." 
		fi
		#delete this till result
		rm result_$1.tmp
	

}
export -f check_svs

cat posclients.list |parallel --no-notice check_svs {}

#profuse task run run-command-posclient ie0027t008 'Test-NetConnection 10.4.1.251 -Port 10113'