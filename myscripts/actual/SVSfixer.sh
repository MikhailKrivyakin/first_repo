#!/bin/bash
#delete previos results
rm result.list


for till in $(cat posclients.list)
	do
		#checking every till in list for connection		
		profuse task run run-command-posclient $till 'Test-NetConnection 10.4.1.251 -Port 10113' > result.tmp
		
		# if output has Fale in it than we try to create new rules and check again		
		if (( $(cat result.tmp |grep False |wc -l) > 0 )); then
		    profuse task run run-command-posclient $till 'New-NetFirewallRule -Name "Allow SVS" -Description "Allow SVS" -DisplayName "Allow SVS" -Enabled:True -Profile Public -Direction Outbound -Action Allow -Protocol TCP -RemoteAddress @("10.4.1.251","10.4.2.251") -RemotePort 10113' >> error_svs.log
			
			#check again
			profuse task run run-command-posclient $till 'Test-NetConnection 10.4.1.251 -Port 10113' > result.tmp
			#if problem persist then inform user	
			if (( $(cat result.tmp |grep False |wc -l) > 0 )); then
					echo "There are some problems with adding firewall rules to the $till . Please chek manualy in the error_svs.log" >> result.list
			else
			#if OK - than inform user and delete profuse logs
					echo "Rules for SVS connection  were added to the $till">>result.list
					rm error_svs.log
			fi
		else 
		#if OK than inform user
			echo "$till has correct firewall rules for SVS connection." >> result.list
		fi
		#delete this till result
		rm result.tmp
	done
cat result.list


#profuse task run run-command-posclient ie0027t008 'Test-NetConnection 10.4.1.251 -Port 10113'