[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $CloudName   
)

Start-Transcript -Path "C:\AZSAdminOMSInt\uploadtoOMS_$CloudName.log"
Set-ExecutionPolicy Bypass -Force
Install-Module -Name OMSIngestionAPI -Force
Install-Module -Name AzureRM.OperationalInsights -Force
Import-Module -Name Azs.Infrastructureinsights.Admin -Force
Import-Module -Name Azs.Update.Admin -Force
Import-Module -Name Azs.Fabric.Admin -Force


#OMS Authentication Variables

$info = Get-Content -Raw -Path "C:\AZSAdminOMSInt\info_$CloudName.txt" | ConvertFrom-Json
$OMSWorkspaceId = $info.OmsWorkspaceID 
$OMSSharedKey = $info.OmsSharedKey

#Cloud2 Authentication details
$Authtype = $info.ParameterSet
$Location2 = $info.Region 
$cloudName2 = $info.CloudName
$State2 = "active"
Switch($Authtype)
{
#Set to AdminAccount or not set(old info file)
    {($_ -eq "AdminAccount") -or ($_ -eq $null)}{
    $UserName2= $info.AzureStackAdminUsername
    $Password2= Get-Content "C:\AZSAdminOMSInt\azspassword_$CloudName.txt"| ConvertTo-SecureString
    $Credential2=New-Object PSCredential($UserName2,$Password2)
    $TenantId2 = $info.TenantId
    }
#Using CertSPN
    "CertSPN"{
    $CertificateThumbprint2 = $info.CertificateThumbprint
    $ApplicationId2 = $info.ApplicationId
    $TenantId2 = $info.TenantId
    }
}


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
Switch($Authtype)
{
#Set to AdminAccount or not set(old info file)
    {($_ -eq "AdminAccount") -or ($_ -eq $null)}{
    if($TenantId2){#Use TenantID if one was provided
        Add-AzureRmAccount -EnvironmentName $cloudName2 -Credential $Credential2 -Tenant $TenantId2
    }
    else{
    Add-AzureRmAccount -EnvironmentName $cloudName2 -Credential $Credential2
    }
    }
#Using CertSPN
    "CertSPN"{
    Add-AzureRmAccount -Environment $cloudName2 -ServicePrincipal -CertificateThumbprint $CertificateThumbprint2 -ApplicationId $ApplicationId2 -TenantId $TenantId2
    }
}

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
