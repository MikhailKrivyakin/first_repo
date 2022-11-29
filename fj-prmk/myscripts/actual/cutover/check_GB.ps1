$testfile=Get-Content /opt/fujitsu/log/globalblue.log | Select-Object -Last 10

if (($testfile -like "*Successfully configured GlobalBlue*") -and ($testfile -like "*Successfully performed on-line configuration for all folders*"))
{
    Write-Host "Globalblue was configured succesfully"
}
else 
{
    Throw "Globalblue package wasn`t configured succesfully for some reason! Check  /opt/fujitsu/log/globalblue.log for details"
}