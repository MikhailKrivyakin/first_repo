Import-Module PKI


$hostname = [System.Net.Dns]::GetHostName()
$pfx = $hostname + '.pfx'
$pfxPath = 'C:\temp\' + $pfx
$cerPath = 'C:\temp\Primark.ie.cer'
$expPfx = $hostname + '_x.pfx'
$expPfxPath = 'C:\temp\' + $expPfx
$appPath = 'C:\opt\app\fujitsu-scom-agent\MOMCertImport.exe'

try{
        $pass = "scom" | ConvertTo-SecureString -AsPlainText -Force
        Import-PfxCertificate -FilePath $pfxPath -Exportable -CertStoreLocation Cert:\LocalMachine\My -Password $pass -ErrorAction Stop
        $password = $pass
}
catch{
        $pass = "P@ssw0rd" | ConvertTo-SecureString -AsPlainText -Force
        Import-PfxCertificate -FilePath $pfxPath -Exportable -CertStoreLocation Cert:\LocalMachine\My -Password $pass -ErrorAction Stop
        $password = $pass
}
Import-Certificate -FilePath $cerPath -CertStoreLocation Cert:\LocalMachine\Root

$cert=GCI -Path Cert:\LocalMachine\My | Where-Object {($_.Subject -match $hostname) -and ($_.Issuer -notmatch 'FujitsuRoot')}
Get-variable -Name password |convertto-securestring -force -ASplainText
Export-PfxCertificate -Cert $cert -ChainOption EndEntityCertOnly -FilePath $expPfxPath -Password $password

Start-Sleep -Seconds 2

$pwd =  [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
C:\opt\app\fujitsu-scom-agent\MOMCertImport.exe $expPfxPath /Password $pwd
