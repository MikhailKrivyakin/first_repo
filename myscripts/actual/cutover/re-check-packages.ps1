$barcklay_version_actual="barclay-version"
$gb_version_actual="gb-version"
$lockdown_version_actual="lockdown-version"
$errors=@()


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
        $errors += "Barclay version is $barclay_current and it is not OK!"
        write-output "Barclay version is $barclay_current and it is not OK!"
        
    }

    if ($gb_current -like "*$gb_version_actual*")
    {
        write-output "globalblue version is OK"    
        
    }
    else
    {
         $errors += "globalblue version is $gb_current and it is not OK!"
        write-output "globalblue version is $gb_current and it is not OK!"
    }

    if ($lockdown_current -like "*$lockdown_version_actual*")
    {
        write-output "lockdown version is OK"    
    }
    else
    {
        
         $errors += "lockdown version is $lockdown_current and it is not OK!"
        write-output "lockdown version is $lockdown_current and it is not OK!"
    }

#final check!
if ($errors.count -gt 0)
{
  Throw "Error! Some of the packages have incorrent versions! Check and re-intasll manually"

}