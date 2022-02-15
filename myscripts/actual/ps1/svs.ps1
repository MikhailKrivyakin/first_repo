$result=Test-NetConnection 10.4.1.251 -Port 10113

if ( $result.TcpTestSucceeded -like "False")
{
New-NetFirewallRule -Name "Allow SVS" -Description "Allow SVS" -DisplayName "Allow SVS" -Enabled:True -Profile Public -Direction Outbound -Action Allow -Protocol TCP -RemoteAddress @("10.4.1.251","10.4.2.251") -RemotePort 10113
write-output "New SVS rule was added"
}
else {
  write-output "SVS connection is OK"
}

$result=Test-NetConnection 10.4.1.251 -Port 10113

if ( $result.TcpTestSucceeded -like "False")
{
  throw "Failed to create Firewall rule for SVS servers"
}
