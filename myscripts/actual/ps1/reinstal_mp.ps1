try {
    #stop services part
        
        Get-Process | Where-Object { $_.ProcessName -eq "BPSSimulator" } | Stop-Process -Force -Verbose  
        Get-Process | Where-Object { $_.ProcessName -eq "Fujitsu.Client.POSCheck" } | Stop-Process -Force -Verbose  
        Get-Process | Where-Object { $_.ProcessName -eq "Fujitsu.Client.POSApp" } | Stop-Process -Force -Verbose    
        Get-Service | Where-Object -FilterScript { ($_.DisplayName.StartsWith("Fujitsu") -or $_.DisplayName.StartsWith("Primark")) -and $_.Status -eq "Running" } |
            Sort-Object { $_.DependentServices.Count } |
            Stop-Service -Force -Verbose 
        Stop-Service -Name "MSSQLSERVER" -Force -Verbose 

    sleep 10

    #enable tlsv1 part 
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello' -Recurse   
        Write-Output 'Multi-Protocol Unified Hello has been removed'
        # Remove PCT 1.0
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0' -Recurse
        Write-Output 'PCT 1.0 has been removed'

        # Enable SSL 2.0 (PCI Compliance)
        New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null

        # Remove SSL 3.0 (PCI Compliance) and disable "Poodle" protection
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0' -Recurse

        # Remove TLS 1.0 for client and server SCHANNEL communications
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0' -Recurse

        # Remove TLS 1.1 for client and server SCHANNEL communication
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1' -Recurse

        # Remove TLS 1.2 for client and server SCHANNEL communications
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2' -Recurse

        # Remove cipher deffinitions
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\*'

        # Set hashes configuration.
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5'
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA'

        # Remove KeyExchangeAlgorithms configuration.
        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman'

        Remove-Item -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\PKCS'

        # Remove cipher suites order .
        Remove-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Name 'Functions'

        # Need to restart MSSQLSERVER once tlsv1 is enabled again
        restart-service -name MSSQLSERVER -force

    sleep 10
    
    #add fw rules part
        $fw1254 = "Fujitsu-Marketplace-Document-Repository-1254-OUT"
        $fw1433 = "Fujitsu-Marketplace-SQL-Management-1433-OUT"

        if (Get-NetFirewallRule $fw1254 -ErrorAction SilentlyContinue) {
            Enable-NetFirewallRule $fw1254
        }
        else {
        $configuration = ConvertFrom-StringData -StringData (
            (Get-Content -Path "C:\opt\Fujitsu\conf\MarketPlace-Store-Register.conf" -Raw) -replace "\\", "\\")
        $EnterpriseServerIP = Resolve-DnsName -Name $configuration["EnterpriseServerAddress"] |
            Select-Object -ExpandProperty IPAddress
        $StoreServerAddress = Resolve-DnsName -Name $configuration["StoreServerAddress"] | Select-Object -ExpandProperty IPAddress

        $MPEAddresses = @($EnterpriseServerIP)
        $MPEAddresses += $configuration["EnterpriseRealAddresses"].Split() # What is this used for? EnterpriseRealAddresses does not exist in $configuration content AFAIK but is part of firewall misc

            New-NetFirewallRule -Name $fw1254 -Description "MP2" -DisplayName "Fujitsu - Marketplace Document Repository, port 1254" -Enabled:True -Profile Public -Direction Outbound -Action Allow -Protocol TCP -RemoteAddress $MPEAddresses -RemotePort 1254

            Write-Host "Done!"
        }

        if (Get-NetFirewallRule $fw1433 -ErrorAction SilentlyContinue) {
            Enable-NetFirewallRule $fw1433
        }
        else {

        New-NetFirewallRule -Name $fw1433 -Description "SQL Mgmt" -DisplayName "Fujitsu - Marketplace SQL Management, port 1433" -Enabled:True -Profile Public -Direction Outbound -Action Allow -Protocol TCP -RemoteAddress $StoreServerAddress -RemotePort 1433

        }

    #eneable-services part
        Start-Service -Name "MSSQLSERVER" -Verbose
    sleep 5
    #remove MP part
        /opt/app/marketplace-pos-till/package.ps1 -Uninstall
    sleep 5
    #fake remove of MP from fjpkg
    fjpkg rm --fake --force marketplace-pos-till

    Write-host "All done. Please perform refresh of posclient to install MP app again."
  





}
catch {
    Throw "Errors during script execution! Check "
}