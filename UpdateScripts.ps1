<#
.Synopsis

Copy this script to the root of your drive and execute to:

1. Pause scheduled tasks
2. Update the scripts from the github repository
3. Update any dependencies
4. Enable the scheduled tasks

#>
#Disable Scheduled Tasks
Disable-ScheduledTask -TaskName "UsageDataUpload1"
Disable-ScheduledTask -TaskName "OperationalDataUpload1"

#Clone Github repository into existing working directory
cd C:\AZSAdminOMSInt
git pull

cd C:\AZSAdminOMSInt
& .\UpdateDependencies.ps1

#Enable Scheduled Tasks
Enable-ScheduledTask -TaskName "UsageDataUpload1"
Enable-ScheduledTask -TaskName "OperationalDataUpload1"
