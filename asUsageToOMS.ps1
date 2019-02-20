[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $CloudName   
)

Start-Transcript -Path "C:\AZSAdminOMSInt\asUsageToOMS_$CloudName.log"
& .\usagesummaryjson.ps1 -CloudName $CloudName

# set execution policy and import OMS Ingestion API. 
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Module -Name AzureRM.OperationalInsights -Force
Install-Module -Name OMSIngestionAPI -Force

& .\uploadToOMS.ps1 -CloudName $CloudName
exit
