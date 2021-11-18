#!/bin/bash
rm output.txt 2>/dev/null
if [ -e /root/certs/$1.pfx  ]; then
	echo "Copying certs to the server"
	/opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a "src=/root/certs/$1.pfx dest=c:/temp/" >>output.txt
	/opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a 'src=/root/certs/Primark.ie.cer dest=c:/temp/'>>output.txt
	sleep 5

	echo "Registring certs"
	profuse task run run-script-posserver $1 '/root/scripts/certs_import/import_certs.ps1'>>output.txt

	echo "Restarting service"
	profuse task run run-command-posserver $1 'Get-Service "HealthService" | Restart-service -Force'>>output.txt


	echo "Apply Add-SCOM managment group script"
	profuse task run run-script-posserver $1 '/tmp/Add-SCOMManagementGroup.ps1'>output.txt

	##checks ##########################################
	echo "Checking cert serial number:"
	profuse task run run-command-posserver $1 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings" |Select-Object -ExpandProperty ChannelCertificateHash'|tail -2 > registr.output
	profuse task run run-command-posserver $1 '$sn=GCI -Path Cert:\LocalMachine\My | Where-Object {($_.Subject -match $env:COMPUTERNAME) -and ($_.Issuer -notmatch "FujitsuRoot")}; $sn.thumbprint' |tail -2 >cert_vault.output
	echo -e "\n ------------------------------------\n Certs valt key:  $(cat registr.output)\n Registr key:     $(cat cert_vault.output)\n ------------------------------------\n "
	echo "Please compare 2 strings above. The should be equal to each other"
	rm *.output 2>/dev/null

	echo "Done! You can see output of the commands in output.txt file"
else 
	echo "No personal certificate found. Please contact HCL team and upload it to /root/certs/"
fi