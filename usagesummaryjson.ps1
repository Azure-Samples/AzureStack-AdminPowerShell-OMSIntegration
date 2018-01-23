
<#
    .Synopsis
    Exports usage meters from Azure Stack to a json file
    .DESCRIPTION
    This entire script is a slight modification on the Usagesummary.ps1 script that is available in the AzureStack-Tools
    repository on github. This script simply store the usage data results in a json file. 
    .EXAMPLE
    Export-AzureStackUsage -StartTime 2/15/2017 -EndTime 2/16/2017 -AzureStackDomain azurestack.local -AADDomain mydir.onmicrosoft.com -Granularity Hourly
#>
function Export-AzureStackUsage {
    Param
    (
        [Parameter(Mandatory = $true)]
        [datetime]
        $StartTime,
        [Parameter(Mandatory = $true)]
        [datetime]
        $EndTime ,
        [Parameter(Mandatory = $true)]
        [String]
        $AzureStackDomain ,
        [Parameter(Mandatory = $true)]
        [String]
        $AADDomain ,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hourly", "Daily")]
        [String]
        $Granularity = 'Hourly',
        [Parameter(Mandatory = $false)]
        [String]
        $jsonFile = "UsageSummary.json",
        [Parameter (Mandatory = $false)]
        [PSCredential]
        $Credential,
        [Parameter(Mandatory = $false)]
        [Switch]
        $TenantUsage,
        [Parameter(Mandatory = $false)]
        [String]
        $Subscription,
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force,
        [Parameter(Mandatory = $false)]
        [String]
        $Region = 'local',
        [Parameter(Mandatory = $false)]
        [String]
        $CloudName1 
    )

    $ctx = Get-AzureRmContext
    if (!$ctx.Subscription){
        Write-Host "Please Connect To Azure Stack"
        Return
    }
    #Initialise result count and meter hashtable
    $Total = 0
    $meters = @{
        'F271A8A388C44D93956A063E1D2FA80B' = 'Static IP Address Usage'
        '9E2739BA86744796B465F64674B822BA' = 'Dynamic IP Address Usage'
        'B4438D5D-453B-4EE1-B42A-DC72E377F1E4' = 'TableCapacity'
        'B5C15376-6C94-4FDD-B655-1A69D138ACA3' = 'PageBlobCapacity'
        'B03C6AE7-B080-4BFA-84A3-22C800F315C6' = 'QueueCapacity'
        '09F8879E-87E9-4305-A572-4B7BE209F857' = 'BlockBlobCapacity'
        'B9FF3CD0-28AA-4762-84BB-FF8FBAEA6A90' = 'TableTransactions'
        '50A1AEAF-8ECA-48A0-8973-A5B3077FEE0D' = 'TableDataTransIn'
        '1B8C1DEC-EE42-414B-AA36-6229CF199370' = 'TableDataTransOut'
        '43DAF82B-4618-444A-B994-40C23F7CD438' = 'BlobTransactions'
        '9764F92C-E44A-498E-8DC1-AAD66587A810' = 'BlobDataTransIn'
        '3023FEF4-ECA5-4D7B-87B3-CFBC061931E8' = 'BlobDataTransOut'
        'EB43DD12-1AA6-4C4B-872C-FAF15A6785EA' = 'QueueTransactions'
        'E518E809-E369-4A45-9274-2017B29FFF25' = 'QueueDataTransIn'
        'DD0A10BA-A5D6-4CB6-88C0-7D585CEF9FC2' = 'QueueDataTransOut'
        'FAB6EB84-500B-4A09-A8CA-7358F8BBAEA5' = 'Base VM Size Hours'
        '6DAB500F-A4FD-49C4-956D-229BB9C8C793' = 'VM size hours'
        '9cd92d4c-bafd-4492-b278-bedc2de8232a' = 'Windows VM Size Hours'
    }
    $recordFile = "UsageSummaryRecord.json"

    #Output Files
    if (Test-Path -Path $jsonFile -ErrorAction SilentlyContinue) {
        if ($Force) {
            Remove-Item -Path $jsonFile -Force
        }
        else {
            Write-Host "$jsonFile alreday exists use -Force to overwrite"
            return
        }
    }
    New-Item -Path $jsonFile -ItemType File | Out-Null
    $Subscription = $ctx.Subscription.Id
    $tokens = $ctx.TokenCache.ReadItems()
    $token = $tokens |  Where Resource -eq $ctx.Environment.ActiveDirectoryServiceEndpointResourceId | Sort ExpiresOn | select -Last 1

    #Setup REST call variables
    $headers = @{ Authorization = ('Bearer {0}' -f $token.AccessToken) }
    $armEndpoint = $ctx.Environment.ResourceManagerUrl

    #build usage uri
    if (!$TenantUsage) {
        $uri = $armEndpoint + '/subscriptions/{0}/providers/Microsoft.Commerce/subscriberUsageAggregates?api-version=2015-06-01-preview&reportedstartTime={1:s}Z&reportedEndTime={2:s}Z&showDetails=true&aggregationGranularity={3}' -f $Subscription, $StartTime, $EndTime, $Granularity
    }
    else {
        $uri = $armEndpoint + '/subscriptions/{0}/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedstartTime={1:s}Z&reportedEndTime={2:s}Z&showDetails=true&aggregationGranularity={3}' -f $Subscription, $StartTime, $EndTime, $Granularity
    }
    $uri1 = $uri
    $usageSummary = @()
    Do {
        $result = Invoke-RestMethod -Method GET -Uri $uri  -Headers $headers -ErrorVariable RestError -Verbose
        if ($RestError) {
            return
        }
        $uri = $result.NextLink
        $count = $result.value.Count
        $Total += $count
        $result.value  | ForEach-Object {
            $record = New-Object -TypeName System.Object
            $resourceInfo = ($_.Properties.InstanceData |ConvertFrom-Json).'Microsoft.Resources'
            $resourceText = $resourceInfo.resourceUri.Replace('\', '/')
            $subscription = $resourceText.Split('/')[2]
            $resourceType = $resourceText.Split('/')[7]
            $resourceName = $resourceText.Split('/')[8]
            $record | Add-Member -Name Id -MemberType NoteProperty -Value $_.id
            $record | Add-Member -Name Name -MemberType NoteProperty -Value $_.Name
            $record | Add-Member -Name Type -MemberType NoteProperty -Value $_.Type
            $record | Add-Member -Name MeterId -MemberType NoteProperty -Value $_.Properties.MeterId
            if ($meters.ContainsKey($_.Properties.MeterId)) {
                $record | Add-Member -Name MeterName -MemberType NoteProperty -Value $meters[$_.Properties.MeterId]
            }
            $record | Add-Member -Name Quantity -MemberType NoteProperty -Value $_.Properties.Quantity
            $record | Add-Member -Name UsageStartTime -MemberType NoteProperty -Value $_.Properties.UsageStartTime
            $record | Add-Member -Name UsageEndTime -MemberType NoteProperty -Value $_.Properties.UsageEndTime
            $record | Add-Member -Name additionalInfo -MemberType NoteProperty -Value $resourceInfo.additionalInfo
            $record | Add-Member -Name location -MemberType NoteProperty -Value $resourceInfo.location
            $record | Add-Member -Name CloudName -MemberType NoteProperty -Value $CloudName1
            $record | Add-Member -Name tags -MemberType NoteProperty -Value $resourceInfo.tags
            $record | Add-Member -Name subscription -MemberType NoteProperty -Value $subscription
            $record | Add-Member -Name resourceType -MemberType NoteProperty -Value $resourceType
            $record | Add-Member -Name resourceName -MemberType NoteProperty -Value $resourceName
            $record | Add-Member -Name resourceUri -MemberType NoteProperty -Value $resourceText
            
            $usageSummary += $record
        }
    }
    While ($count -ne 0)
    ConvertTo-Json -InputObject $usageSummary | Out-File $jsonFile
    ConvertTo-Json -InputObject $usageSummary | Out-File -Append $recordFile

    # Write-Host $usageSummary
    Write-Host "Complete - $Total Usage records written to $jsonFile"
}


$today = Get-Date
$yesterday = $today.addDays(-1)
$dayBeforeYesterday = $yesterday.addDays(-1)

$usageStartTime = $dayBeforeYesterday.ToShortDateString()
$usageEndTime = $yesterday.ToShortDateString()

$info = Get-Content -Raw -Path "C:\AZSAdminOMSInt\info.txt" | ConvertFrom-Json
$Username = $info.AzureStackAdminUsername
$Password= Get-Content "C:\AZSAdminOMSInt\azspassword.txt"| ConvertTo-SecureString
$aadCred = New-Object PSCredential($Username, $Password)
$cloudName2 = $info.CloudName
$Location2 = $info.Region 
$api = "adminmanagement"
$AzureStackDomain = $info.Fqdn
$AzureStackAdminEndPoint = 'https://{0}.{1}.{2}' -f $api, $Location2, $AzureStackDomain


$pos = $Username.IndexOf('@')
$aadDomain = $Username.Substring($pos + 1)


Add-AzureRMEnvironment -Name "$cloudName2" -ArmEndpoint $AzureStackAdminEndPoint
Login-AzureRmAccount -EnvironmentName $cloudName2 -Credential $aadCred

# store the result of the usage api records for the time period from the day before yesterday to yesterday in a json file. 
Export-AzureStackUsage -StartTime $usageStartTime -EndTime $usageEndTime -AzureStackDomain $info.Fqdn -AADDomain $aadDomain  -Region $info.Region -Credential $aadCred -Granularity Hourly -Force -CloudName1 $info.CloudName
