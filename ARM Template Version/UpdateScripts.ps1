<#
.Synopsis

Copy this script to the root of your drive and execute to:

1. Pause scheduled tasks
2. Update the scripts from the github repository
3. Update any dependencies
4. Enable the scheduled tasks
 
Note you may see the following error during execution
git : From https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration
At C:\UpdateScripts.ps1:18 char:1
+ git pull
+ ~~~~~~~~
    + CategoryInfo          : NotSpecified: (From https://gi...-OMSIntegration:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   3bf49bb..6acc252  master     -> origin/master
   
 Updates to the scripts will happen despite this error.

#>
#Disable Scheduled Tasks
Disable-ScheduledTask -TaskName "UsageDataUpload1"
Disable-ScheduledTask -TaskName "OperationalDataUpload1"

#Add environment variable for Git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Clone Github repository into existing working directory
cd C:\AZSAdminOMSInt
git pull "https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration.git"

cd C:\AZSAdminOMSInt
& .\UpdateDependencies.ps1

#Enable Scheduled Tasks
Enable-ScheduledTask -TaskName "UsageDataUpload1"
Enable-ScheduledTask -TaskName "OperationalDataUpload1"
