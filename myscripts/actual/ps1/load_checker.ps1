$CPUload=(Get-WmiObject Win32_Processor).LoadPercentage 
$RAMload=(Get-WMIObject Win32_OperatingSystem).FreePhysicalMemory/1kb
Write-host "CPU Usage: $CPUload%. | Free Memory: $RAMload MB"
echo "_________________________________________________"

If ($CPUload -gt 80 -or $RAMload -lt 6000)
{
    Write-host WARNING! High usage of resourses!
    $cores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
    $tmp = Get-WmiObject Win32_PerfFormattedData_PerfProc_Process |
    select-object -property Name, @{Name = "CPU"; Expression = {($_.PercentProcessorTime/$cores)}}, @{Name = "PID"; Expression = {$_.IDProcess}}, @{"Name" = "Memory(MB)"; Expression = {[int]($_.WorkingSetPrivate/1mb)}}|Where-Object {$_.Name -notmatch "^(idle|_total|system)$"}|Sort-Object -Property "Memory(MB)" -Descending|select-object -First 15
    $tmp | Format-Table -Autosize -Property Name, CPU, "Memory(MB)";
} 
