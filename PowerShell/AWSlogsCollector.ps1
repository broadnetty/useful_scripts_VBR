
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}
# Now running elevated so launch the script:


$veeamregs = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication'
$veeamlogpath = $env:ProgramData + '\Veeam\Backup'
$veeamlogstargetpath = 'C:\Temp\VeeamLogs'

New-Item -ItemType Directory -Force -Path $veeamlogstargetpath > $null
if (-not ([string]::IsNullOrEmpty($veeamregs.LogDirectory ))) {
$veeamlogpath = $veeamregs.LogDirectory
}

Write-Host '
|========================================================|
|                                                        |
| Logs will be collected to the folder C:\Temp\VeeamLogs |
|                                                        |
|========================================================|'


Write-Host '
Changing directory to ' $veeamlogpath

cd $veeamlogpath


Remove-Item -Force -Path LogCollector -Recurse 

New-Item -ItemType Directory -Force -Path LogCollector > $null
Write-Host '
LogCollector folder created'

Copy-Item -Path Satellites -Destination LogCollector -Recurse
Copy-Item -Path Utils -Destination LogCollector -Recurse
Copy-Item -Path Console -Destination LogCollector -Recurse
Copy-Item -Path Svc.VeeamBackup.log -Destination LogCollector -Recurse
Copy-Item -Path *Offload* -Destination LogCollector -Recurse

$timestamp = Get-Date -Format 'dd.MM.yyyy_HH-mm'
$archivepath = $veeamlogstargetpath + '\VeeamOffloadLogs_' + $timestamp + '.zip'
Compress-Archive -Path LogCollector -DestinationPath $archivepath
Remove-Item -Force -Path LogCollector -Recurse 
Write-Host '
LogCollector folder removed'


Explorer.exe $veeamlogstargetpath

