$barcklay_version_actual="barclay-version"
$gb_version_actual="gb-version"
$lockdown_version_actual="lockdown-version"



$barclay_current=fjpkg q fujitsu-barclay-smartpay
$gb_current=fjpkg q fujitsu-globalblue-windows
#$opos_current=fjpkg q fujitsu-opos-drivers
$lockdown_current=fjpkg q fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809
#if block
    if ($barclay_current -like "*$barcklay_version_actual*")
    {
    write-output "Barclay version is OK"    

    }
    else
    {
        write-output "Removing barclay package"
        #fjpkg rm fujitsu-barclay-smartpay 
    }

    if ($gb_current -like "*$gb_version_actual*")
    {
        write-output "globalblue version is OK"    
        
    }
    else
    {
        write-output " removing globalblue"   
        #fjpkg rm fujitsu-globalblue-windows   
    }
    if ($lockdown_current -like "*$lockdown_version_actual*")
    {
        write-output "lockdown version is OK"    
    }
    else
    {
        write-output " removing lockdown package" 
        #fjpkg rm fujitsu-windows-lockdown-WINDOWS_10_ENTERPRISE_2019_LTSC_1809 
    }