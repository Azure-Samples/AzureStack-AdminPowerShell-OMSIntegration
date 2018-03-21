Start-Transcript -Path C:\AZSAdminOMSInt\uploadtoOMS.log
$info = Get-Content -Raw -Path "C:\AZSAdminOMSInt\info.txt" | ConvertFrom-Json
$azureUsername = $info.AzureUsername
$azurePassword = Get-Content "C:\AZSAdminOMSInt\azpassword.txt" | ConvertTo-SecureString
$azureCredential = New-Object PSCredential($azureUsername, $azurePassword)
$azureSubscription = $info.AzureSubscription

Login-AzureRmAccount -Credential $azureCredential -SubscriptionId $azureSubscription

# get oms workspace name and resource group from previously created file. 
$omsWorkspaceName = $info.OmsWorkspaceName
$omsResourceGroupName = $info.OmsResourceGroup

# get workspace key
$wskey = Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $omsResourceGroupName -Name $omsWorkspaceName
# get workspace
$ws = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $omsResourceGroupName -Name $omsWorkspaceName

$usageSummary = Get-Content -Raw -Path "UsageSummary.json" | ConvertFrom-Json
$logType = "Usage"
$deploymentGuid = $info.DeploymentGuid

# get subscription to tenant mapping
Import-Module .\Get-AllCurrentSubscriptions.psm1
$Username = $info.AzureStackAdminUsername
$Password = Get-Content "C:\AZSAdminOMSInt\azspassword.txt" | ConvertTo-SecureString
$Credential = New-Object PSCredential($Username, $Password)
$pos = $Username.IndexOf('@')
$aadDomain = $Username.Substring($pos + 1)
$AzureStackDomain = $info.Fqdn
$Region = $info.Region
$subTenantHash = Get-AllCurrentSubscriptions -Credential $Credential -AADDomain $aadDomain -AzureStackDomain $AzureStackDomain -Region $Region

foreach ($entry in $usageSummary)
{
    $usageWrapper = @()

    $tenant = "Deleted Subscriptions"
    if ($subTenantHash.ContainsKey($entry.subscription)){
        $tenant = $subTenantHash[$entry.subscription]
    }

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
    send-omsapiingestionfile -customerId $ws.CustomerId -sharedKey $wskey.PrimarySharedKey -body $usageJson -logType $logType -TimeStampField $Timestamp
}
