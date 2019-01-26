#Usage Data Upload
$action = New-ScheduledTaskAction -Execute 'Powershell' `
-Argument '.\asUsageToOMS.ps1' -WorkingDirectory "C:\AZSAdminOMSInt"
$description = "Daily upload of usage data from azure stack to OMS"
$taskName = "UsageDataUpload1"

$trigger = New-ScheduledTaskTrigger -Daily -At 9am
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM"

$twoHours = New-TimeSpan -Hour 2
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit $twoHours

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $principal -Description $description -Settings $settings

#Operational Data Upload
$action = New-ScheduledTaskAction -Execute 'Powershell' `
-Argument '.\OpsDataToOMS.ps1' -WorkingDirectory "C:\AZSAdminOMSInt"
$description = "Daily upload of operational data from azure stack to OMS"
$taskName = "OperationalDataUpload1"

$trigger = New-ScheduledTaskTrigger -once -at (Get-date) -RepetitionInterval (New-TimeSpan -Minutes 13) -RepetitionDuration (New-TimeSpan -Days 9999) 
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM"

$tenMinutes = New-TimeSpan -Minute 10
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit $tenMinutes

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $principal -Description $description -Settings $settings