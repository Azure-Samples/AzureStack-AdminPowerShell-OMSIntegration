Start-Transcript -Path C:\AZSAdminOMSInt\asUsageToOMS.log
& .\usagesummaryjson.ps1

# set execution policy and import OMS Ingestion API. 
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Module -Name AzureRM.OperationalInsights -Force
Install-Module -Name OMSIngestionAPI -Force

& .\uploadToOMS.ps1
exit
