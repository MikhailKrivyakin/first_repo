#!/bin/bash

# you should run this script as ./mqscfiles.sh **####*### rus***, where **####*### -server name, and rus*** - your /home/ directory

agentnumber=$(echo $1 | cut -c 4-6)
#obtaining mqsc file to your /home/
/opt/fujitsu/profuse/zonemaster/tasks/ansible/./ansible2_site.sh $1 -m fetch -a "flat=yes src=C:/ProgramData/IBM/MQ/mqft/config/QDL2MFT1/agents/WIN_CLIENT_MPESTR_0$agentnumber/WIN_CLIENT_MPESTR_0"$agentnumber"_create.mqsc  dest=/home/$2/"
/opt/fujitsu/profuse/zonemaster/tasks/ansible/./ansible2_site.sh $1 -m fetch -a "flat=yes src=C:/ProgramData/IBM/MQ/mqft/config/QDL2MFT1/agents/WIN_CLIENT_MPESTR_0$agentnumber/WIN_CLIENT_MPESTR_0"$agentnumber"_delete.mqsc  dest=/home/$2/"

#creating "rejected directory"
profuse task run run-command-posserver $1 "New-Item -Path 'C:\DIGI FTP\nsb\coalition\edu\rejected' -ItemType Directory"
#copy MoveFiles.class to server
/opt/fujitsu/profuse/zonemaster/tasks/ansible/ansible2_site.sh $1 -m win_copy -a 'src="/root/scripts/mqscfiles/MoveFiles.class" dest=C:/ProgramData/IBM/MQ/mqft/config/QDL2MFT1/agents/WIN_CLIENT_MPESTR_0'$agentnumber'/exits/mft/samples/'

#stop agent
profuse task run run-command-posserver $1 'Get-Service -Name *mqmft*; Get-Service -Name *mqmft* | Stop-Service; Get-Service -Name *mqmft*'
sleep 5

#add string to agent.properties
profuse task run run-command-as-system-posserver $1 "Add-Content C:\ProgramData\IBM\MQ\mqft\config\QDL2MFT1\agents\WIN_CLIENT_MPESTR_0$agentnumber\agent.properties 'sourceTransferEndExitClasses=mft.samples.MoveFiles'"

#start agent
profuse task run run-command-posserver $1 'Get-Service -Name *mqmft*; Get-Service -Name *mqmft* | Start-Service; Get-Service -Name *mqmft*'

# export data from agent.properties

profuse task run run-command-posserver $1 "cat C:\ProgramData\IBM\MQ\mqft\config\QDL2MFT1\agents\WIN_CLIENT_MPESTR_0$agentnumber\agent.properties"

echo -e "\n\n****************************************\n MQSC files from server $1 were added to /home/$2/. You can send them via email. Also, above you can see agent.properties content to send it too "


