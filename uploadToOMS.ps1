Start-Transcript -Path C:\AZSAdminOMSInt\uploadtoOMS.log
Set-ExecutionPolicy Bypass -Force
Install-Module -Name OMSIngestionAPI -Force
Install-Module -Name AzureRM.OperationalInsights -Force
Import-Module -Name Azs.Infrastructureinsights.Admin -Force
Import-Module -Name Azs.Update.Admin -Force
Import-Module -Name Azs.Fabric.Admin -Force


#OMS Authentication Variables

$info = Get-Content -Raw -Path "C:\AZSAdminOMSInt\info.txt" | ConvertFrom-Json
$OMSWorkspaceId = $info.OmsWorkspaceID 
$OMSSharedKey = $info.OmsSharedKey

#Cloud2 Authentication details
$Location2 = $info.Region 
$cloudName2 = $info.CloudName
$State2 = "active"
$UserName2= $info.AzureStackAdminUsername
$Password2= Get-Content "C:\AZSAdminOMSInt\azspassword.txt"| ConvertTo-SecureString
$Credential2=New-Object PSCredential($UserName2,$Password2)

$deploymentGuid = $info.DeploymentGuid
$api = "adminmanagement"
$AzureStackDomain = $info.Fqdn
$AzureStackAdminEndPoint = 'https://{0}.{1}.{2}' -f $api, $Location2, $AzureStackDomain
$AzSOEM = $info.Oem 

#################################################################################
#                           OPERATIONAL DATA
#
#################################################################################
##############################################################################################################
# Get Data via PS for Cloud 2
Add-AzureRMEnvironment -Name $cloudName2 -ArmEndpoint $AzureStackAdminEndPoint
Add-AzureRmAccount -EnvironmentName $cloudName2 -Credential $Credential2

#################################################################################
#                           USAGE DATA
#
#################################################################################

$usageSummary = Get-Content -Raw -Path "UsageSummary.json" | ConvertFrom-Json
$logType = "Usage"
$deploymentGuid = $info.DeploymentGuid

#$subTenantHash = @{}
   # $result | ForEach-Object {
   #     $subTenantHash.Add($_.SubscriptionId, $_.Owner)
  #  }

foreach ($entry in $usageSummary)
{
    $usageWrapper = @()

    $tenant = "Deleted Subscriptions"
  #  if ($subTenantHash.ContainsKey($entry.subscription)){
   #    $tenant = $subTenantHash[$entry.subscription]
  #  }
 
    $usageData = New-Object psobject -Property @{
        Type = 'Usage';
        ID = $entry.Id;
        Name = $entry.Name;
        UsageType = $entry.Type;
        MeterID = $entry.MeterId;
        MeterName = $entry.MeterName;
        Quantity = $entry.Quantity;
        StartTime = $entry.UsageStartTime;
        EndTime = $entry.UsageEndTime;
        AdditionalInfo = $entry.additionalInfo;
        Location = $entry.location;
        CloudName = $entry.CloudName;
        Tags = $entry.tags;
        SubscriptionID = $entry.subscription;
        ResourceType = $entry.resourceType;
        ResourceName = $entry.resourceName;
        ResourceURI = $entry.resourceUri;
        DeploymentGuid = $deploymentGuid;
        Tenant = $tenant;
        Timestamp = (Get-Date).ToUniversalTime();
    }

    $usageWrapper += $usageData
    $usageJson = ConvertTo-Json -InputObject $usageWrapper

    Write-Host $usageJson
    $Timestamp = "Timestamp"
    #Upload JSON to OMS
    #send-omsapiingestionfile -customerId $ws.CustomerId -sharedKey $wskey.PrimarySharedKey -body $usageJson -logType $logType -TimeStampField $Timestamp
    Send-OMSAPIIngestionFile -customerId $OMSWorkspaceId -sharedKey $OMSSharedKey -body $usageJson -logType $logType -TimeStampField $Timestamp


}
