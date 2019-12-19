
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}
# Now running elevated so launch the script:

function End-Script {
        Write-Host -ForegroundColor Yellow "The log collection is complete. Please add the folder $veeamlogpath\LogCollector to an archive (.zip, .7z), and upload the archive to the FTP provided by Veeam Technical Support" 
}   

function Get-VBRServerComponentLogs {


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
        
        Write-Host -ForegroundColor Yellow "Compressing Directory"
        If(Test-path $archivepath) {Remove-item $archivepath}
        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipfile]::CreateFromDirectory("$veeamlogpath\LogCollector", $archivepath) 
            if (!(Test-Path $archivepath)) {
                End-Script
            } else {
        Write-Host "Done."
        Write-Host -ForegroundColor Yellow "The data has been collected. Please upload the latest log to the FTP site." 
        
        #Compress-Archive -Path LogCollector -DestinationPath $archivepath
        Remove-Item -Force -Path LogCollector -Recurse 
        Write-Host '
        LogCollector folder removed'
        }
}


##Check for .Net 4.5
$NetValid = $false
$NetChk = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 378389
If ($NetChk -eq $true){ $NetValid = $true }
$veeamregs = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication'
$veeamlogpath = $env:ProgramData + '\Veeam\Backup'
$veeamlogstargetpath = 'C:\Temp\VeeamLogs'


If ($NetValid -eq $true){

        Get-VBRServerComponentLogs




        Explorer.exe $veeamlogstargetpath

    }   
else {
    End-Script
}


#$servaki = Get-VBRBackupRepository -ScaleOut | Get-VBRRepositoryExtent
#
#Export-VBRLogs -Server $hostiki -FolderPath "C:\temp\VeeamLogs"   -From 18/12/2019