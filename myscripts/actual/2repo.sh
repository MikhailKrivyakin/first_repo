#!/bin/bash

country=$(hostname |cut -c 3-4)

function f_packeges_to_repos
{

[ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809-1.3.23.x64.7z ] && cp ./fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809-1.3.23.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "Client Lockdown package was added" || echo "Client Lockdown package is OK"
[ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSSERVER-Platform-Updates/fjpkg/x64/fujitsu-windows-lockdown-WINDOWS_SERVER_2016_STANDARD-1.3.23.x64.7z ] && cp ./fujitsu-windows-lockdown-WINDOWS_SERVER_2016_STANDARD-1.3.23.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSSERVER-Platform-Updates/fjpkg/x64/ && echo "Server Lockdown package was added" || echo "Server Lockdown package is OK"
[ ! -f  /opt/fujitsu/profuse/zonemaster/data/cm/releases/windows-firewall-rules/repos/WINDOWS-SITE-Windows-Firewall-Rules/fjpkg/x64/fujitsu-firewall-rules-windows-1.0.7.x64.7z ] && cp ./fujitsu-firewall-rules-windows-1.0.7.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/windows-firewall-rules/repos/WINDOWS-SITE-Windows-Firewall-Rules/fjpkg/x64/ && echo "Firewall package was added" || echo "Firewall package is OK"


}
function f_create_repo
{
    fjpkg createrepo -U /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates >/dev/null  
    fjpkg createrepo -U /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSSERVER-Platform-Updates >/dev/null  
    fjpkg createrepo -U /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates >/dev/null  
    fjpkg createrepo -U /opt/fujitsu/profuse/zonemaster/data/cm/releases/windows-firewall-rules/repos/WINDOWS-SITE-Windows-Firewall-Rules/ >/dev/null  
    echo "Repos were re-created"

}
echo " -------------------------------------------------------"
case $country in
  "pl")
        echo "Country is $country"
        f_packeges_to_repos
        [ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-globalblue-windows-1.2110.3162.x64.7z ] && cp ./fujitsu-globalblue-windows-1.2110.3162.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "Globalblue v 2110 package was added to repo 4.6.8" || echo "Globalblue package is OK in repo 4.6.8"
        [ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-globalblue-windows-1.2110.3162.x64.7z ] && cp ./fujitsu-globalblue-windows-1.2110.3162.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "Globalblue v 2110 package was added to repo 4.6.3" || echo "Globalblue package is OK in repo 4.6.3"
        f_create_repo
        
  ;;
  "it")
        echo "Country is $country"
        f_packeges_to_repos
        [ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-opos-drivers-2.6.12.x64.7z ] && cp ./fujitsu-opos-drivers-2.6.12.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "OPOS drivers v.2.6.12 package were added to repo 4.6.3" || echo "OPOS driver is OK in repo 4.6.3"
        [ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-opos-drivers-2.6.12.x64.7z ] && cp ./fujitsu-opos-drivers-2.6.12.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "OPOS drivers v.2.6.12 package were added to repo 4.6.8" || echo "OPOS driver is OK in repo 4.6.8"
        f_create_repo
  
  ;;
  "pt")
        echo "Country is $country"
        f_packeges_to_repos
        [ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-opos-drivers-2.6.12.x64.7z ] && cp ./fujitsu-opos-drivers-2.6.12.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.8/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "OPOS drivers v.2.6.12 package were added to repo 4.6.8" || echo "OPOS driver is OK in repo 4.6.8"
        f_create_repo
  ;;
  "ie")
        echo "Country is $country"
        f_packeges_to_repos
        [ ! -f /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/fujitsu-globalblue-windows-1.2011.2696_2.x64.7z ] && cp ./fujitsu-globalblue-windows-1.2011.2696_2.x64.7z /opt/fujitsu/profuse/zonemaster/data/cm/releases/4.6.3/repos/WINDOWS-SITE-POSCLIENT-Platform-Updates/fjpkg/x64/ && echo "Globalblue v 2011 package was added to repo 4.6.3" || echo "Globalblue package is OK in repo 4.6.3"
        f_create_repo
  ;;
    *)
        echo "Country is $country"
        f_packeges_to_repos
        f_create_repo
       
  ;;
  esac
echo "Done. Ready to sync"
echo " -------------------------------------------------------"