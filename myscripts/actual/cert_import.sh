#!/bin/bash

if [ -e /root/certs/$1.pfx  ]; then
	echo "Copying certs to the server"
	/opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a "src=/root/certs/$1.pfx dest=c:/temp/" >>${1}_output.txt
	/opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a 'src=/root/certs/Primark.ie.cer dest=c:/temp/'>>${1}_output.txt
	sleep 5

	echo "Registring certs"
	profuse task run run-script-posserver $1 '/root/scripts/certs_import/import_certs.ps1'>>${1}_output.txt

	echo "Restarting service"
	profuse task run run-command-posserver $1 'Get-Service "HealthService" | Restart-service -Force'>>${1}_output.txt


	echo "Apply Add-SCOM managment group script"
	if [ -e /tmp/Add-SCOMManagementGroup.ps1 ];then 
	profuse task run run-script-posserver $1 '/tmp/Add-SCOMManagementGroup.ps1'>${1}_output.txt
	else 
		echo -e "WARNING!\n Add-SCOMManagementGroup.ps1 is absent on this Zonemaster! You need to find it and run on this server using 'run-script' profuse task"
	fi
	##checks ##########################################
	echo "Checking cert serial number:"
	profuse task run run-command-posserver $1 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings" |Select-Object -ExpandProperty ChannelCertificateHash'|tail -2 > registr.output_$1
	profuse task run run-command-posserver $1 '$sn=GCI -Path Cert:\LocalMachine\My | Where-Object {($_.Subject -match $env:COMPUTERNAME) -and ($_.Issuer -match "Primark.ie")}; $sn.thumbprint' |tail -2 >cert_vault.output_$1
	echo -e "\n ------------------------------------\n Certs valt key:  $(cat registr.output_$1)\n Registr key:     $(cat cert_vault.output_$1)\n ------------------------------------\n "
	echo "Please compare 2 strings above. The should be equal to each other"
	rm *.output_$1 2>/dev/null

	echo "Done! You can see output of the commands in output.txt file"
else 
	echo "No personal certificate found. Please contact HCL team and upload it to /root/certs/"
fi