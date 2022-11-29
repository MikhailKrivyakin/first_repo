# Disable Multi-Protocol Unified Hello
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force | Out-Null
Write-Output 'Multi-Protocol Unified Hello has been disabled.'

$Protocols = @{
    'PCT 1.0' = @{
        Enabled = 0
        DisabledByDefault = 1
     }
     'SSL 2.0' = @{
        Enabled = 0
        DisabledByDefault = 1
     }
     'SSL 3.0' = @{
        Enabled = 0
        DisabledByDefault = 1
     }
     'TLS 1.0' = @{
        Enabled = 0
        DisabledByDefault = 1
     }
     'TLS 1.1' = @{
        Enabled = 0
        DisabledByDefault = 1
     }
     'TLS 1.2' = @{
        Enabled = 0xffffffff
        DisabledByDefault = 0
     }
}
$ProtocolsRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
foreach ($Protocol in $Protocols.Keys) {
    foreach ($type in 'Server','Client'){
        New-Item "$($ProtocolsRegPath)\$($Protocol)\$($type)" -Force | Out-Null
        New-ItemProperty -path "$($ProtocolsRegPath)\$($Protocol)\$($type)" -name 'Enabled' -value $protocols.$protocol.Enabled -PropertyType 'DWord' -Force | Out-Null
        New-ItemProperty -path "$($ProtocolsRegPath)\$($Protocol)\$($type)" -name 'DisabledByDefault' -value $protocols.$protocol.DisabledByDefault -PropertyType 'DWord' -Force | Out-Null
    }
    Write-Output "$($Protocol) has been disabled."
}

# Re-create the ciphers key.
New-Item 'HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers' -Force | Out-Null
# Disable insecure/weak ciphers. And enable secure
$Ciphers = @{
  'DES 56/56' = 0
  'NULL'= 0
  'RC2 128/128' = 0
  'RC2 40/128' = 0
  'RC2 56/128' = 0
  'RC4 40/128' = 0
  'RC4 56/128' = 0
  'RC4 64/128' = 0
  'RC4 128/128' = 0
  'Triple DES 168/168' = 0
  'AES 128/128' = 0xffffffff
  'AES 256/256' = 0xffffffff
}
Foreach ($Cipher in $Ciphers.Keys) {
  $key = (Get-Item HKLM:\).OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey($Cipher)
  $key.SetValue('Enabled', $Ciphers.$Cipher, 'DWord')
  $key.close()
}

# Set hashes configuration.
$Hashes = @{
    'MD5' = 0
    'SHA' = 0
    'SHA256' = 0xffffffff
    'SHA384' = 0xffffffff
    'SHA512' = 0xffffffff
}
foreach ($Hash in $Hashes.Keys) {
    New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\$($Hash)" -Force | Out-Null
    New-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\$($Hash)" -name Enabled -value $Hashes.$Hash -PropertyType 'DWord' -Force | Out-Null
}

# Set KeyExchangeAlgorithms configuration.
$KeyExchangeAlgorithms = @{
    'Diffie-Hellman' = 0xffffffff
    'PKCS' = 0xffffffff
}
foreach ($Algorythm in $KeyExchangeAlgorithms.Keys){
    New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\$($Algorythm)" -Force | Out-Null
    New-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\$($Algorythm)" -name Enabled -value $KeyExchangeAlgorithms.$Algorythm -PropertyType 'DWord' -Force | Out-Null
}

# Set cipher suites order as secure as possible (Enables Perfect Forward Secrecy).
$cipherSuitesOrder = @(
  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P521',
  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P384',
  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P256',
  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P521',
  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P384',
  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P256',
  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P521',
  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P521',
  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P384',
  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P256',
  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P384',
  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P256',
  'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P521',
  'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384',
  'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P521',
  'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384',
  'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256',
  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384_P521',
  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384_P384',
  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P521',
  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P384',
  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P256',
  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P521',
  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P384',
  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P256',
  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P521',
  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P384',
  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P256',
  'TLS_DHE_DSS_WITH_AES_256_CBC_SHA256',
  'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256',
  'TLS_DHE_DSS_WITH_AES_128_CBC_SHA',
  'TLS_RSA_WITH_AES_256_CBC_SHA256',
  'TLS_RSA_WITH_AES_128_CBC_SHA256'
)
$cipherSuitesAsString = [string]::join(',', $cipherSuitesOrder)
New-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -name 'Functions' -value $cipherSuitesAsString -PropertyType 'String' -Force | Out-Null
