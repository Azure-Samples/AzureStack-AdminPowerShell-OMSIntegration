
<#
    .Synopsis
    Exports usage meters from Azure Stack to a json file
    .DESCRIPTION
    This entire script is a slight modification on the Usagesummary.ps1 script that is available in the AzureStack-Tools
    repository on github. This script simply store the usage data results in a json file. 
    .EXAMPLE
    Export-AzureStackUsage -StartTime 2/15/2017 -EndTime 2/16/2017 -AzureStackDomain azurestack.local -AADDomain mydir.onmicrosoft.com -Granularity Hourly
#>
Start-Transcript -Path C:\AZSAdminOMSInt\usagesummaryjson.log

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
    #Initialize result count and meter hashtable
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
        #Added in new Meters and Hashcodes
        '190c935e-9ada-48ff-9ab8-56ea1cf9adaa' = 'App Service Virtual core hours'
        '957e9f36-2c14-45a1-b6a1-1723ef71a01d' = 'Shared App Service Hours'
        '539cdec7-b4f5-49f6-aac4-1f15cff0eda9' = 'Free App Service Hours'
        'db658d61-ef2d-4888-9843-72f5c774fd3c' = 'Small Basic App Service Hours'
        '27b01104-e0df-4f30-a171-f1b00ecb76b3' = 'Medium Basic App Service Hours'
        '50db6a92-5dff-4c9b-8238-8ea5fb1be107' = 'Large Basic App Service Hours'
        '88039d51-a206-3a89-e9de-c5117e2d10a6' = 'Small Standard App Service Hours'
        '83a2a13e-4788-78dd-5d55-2831b68ed825' = 'Medium Standard App Service Hours'
        '1083b9db-e9bb-24be-a5e9-d6fdd0ddefe6' = 'Large Standard App Service Hours'
        '26bd6580-c3bd-4e7e-8092-58b28eb1bb94' = 'Small Premium App Service Hours'
        'a1cba406-e83e-45c3-bd36-485191c215d9' = 'Medium Premium App Service Hours'
        'a2104a9d-5a78-4f8f-a2df-034bd43d602d' = 'Large Premium App Service Hours'
        'a91eed6c-dbbc-4532-859c-86de776433a4' = 'Extra Large Premium App Service Hours'
        '73215a6c-fa54-4284-b9c1-7e8ec871cc5b' = 'Web Process'
        '5887d39b-0253-4e12-83c7-03e1a93dffd9' = 'External Egress Bandwidth'
        '264acb47-ad38-47f8-add3-47f01dc4f473' = 'SNI SSL'
        '60b42d72-dc1c-472c-9895-6c516277edb4' = 'IP SSL'
        'd1d04836-075c-4f27-bf65-0a1130ec60ed' = 'Functions Compute'
        '67cc4afc-0691-48e1-a4b8-d744d1fedbde' = 'Functions Requests'
        'CBCFEF9A-B91F-4597-A4D3-01FE334BED82' = 'DatabaseSizeHourSqlMeter'
        'E6D8CFCD-7734-495E-B1CC-5AB0B9C24BD3' = 'DatabaseSizeHourMySqlMeter'
        'EBF13B9F-B3EA-46FE-BF54-396E93D48AB4' = 'Key Vault transactions'
        '2C354225-B2FE-42E5-AD89-14F0EA302C87' = 'Advanced keys transactions'
    }
    $recordFile = "UsageSummaryRecord.json"

        
    #Output Files to JSON
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
   
    $result = Get-AzsSubscriberUsage -ReportedStartTime ("{0:yyyy-MM-ddT00:00:00.00Z}" -f $StartTime)  -ReportedEndTime ("{0:yyyy-MM-ddT00:00:00.00Z}" -f $EndTime) -AggregationGranularity $Granularity

    Do {

    #Build a subscription hashtable
    $subtable = @{}
    $subs = Get-AzsUserSubscription
    $subs | ForEach-Object {$subtable.Add($_.SubscriptionId, $_.Owner)}
        
        $usageSummary = @()

        if ($RestError) {
            return
        }
        $count = $result.value.Count
        $Total += $count
        $result  | ForEach-Object {
        $record = New-Object -TypeName System.Object
        $resourceInfo = ($_.InstanceData | ConvertFrom-Json).'Microsoft.Resources'
        $resourceText = $resourceInfo.resourceUri
        $subscription = $resourceText.Split('/')[2]
        $resourceType = $resourceText.Split('/')[7]
        $resourceGroup = $resourceText.Split('/')[4]
        $resourceName = $resourceText.Split('/')[8]


            $record | Add-Member -Name Id -MemberType NoteProperty -Value $_.id
            $record | Add-Member -Name Name -MemberType NoteProperty -Value $_.Name
            $record | Add-Member -Name Type -MemberType NoteProperty -Value $_.Type
            $record | Add-Member -Name CloudName -MemberType NoteProperty -Value $CloudName1
      


            $record | Add-Member -Name UsageStartTime -MemberType NoteProperty -Value $_.UsageStartTime
            $record | Add-Member -Name UsageEndTime -MemberType NoteProperty -Value $_.UsageEndTime
            $record | Add-Member -Name MeterName -MemberType NoteProperty -Value $meters[$_.MeterId]
            $record | Add-Member -Name Quantity -MemberType NoteProperty -Value $_.Quantity
            $record | Add-Member -Name resourceType -MemberType NoteProperty -Value $resourceType
            $record | Add-Member -Name location -MemberType NoteProperty -Value $resourceInfo.location
            $record | Add-Member -Name resourceGroup -MemberType NoteProperty -Value $resourceGroup
            $record | Add-Member -Name resourceName -MemberType NoteProperty -Value $resourceName
            $record | Add-Member -Name subowner -MemberType NoteProperty -Value $subtable[$subscription]
            $record | Add-Member -Name tags -MemberType NoteProperty -Value $resourceInfo.tags
            $record | Add-Member -Name MeterId -MemberType NoteProperty -Value $_.MeterId
            $record | Add-Member -Name additionalInfo -MemberType NoteProperty -Value $resourceInfo.additionalInfo
            $record | Add-Member -Name subscription -MemberType NoteProperty -Value $subscription
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


Add-AzureRMEnvironment -Name $cloudName2 -ArmEndpoint $AzureStackAdminEndPoint
Login-AzureRmAccount -EnvironmentName $cloudName2 -Credential $aadCred

# store the result of the usage api records for the time period from the day before yesterday to yesterday in a json file. 
Export-AzureStackUsage -StartTime $usageStartTime -EndTime $usageEndTime -AzureStackDomain $info.Fqdn -AADDomain $aadDomain  -Region $info.Region -Credential $aadCred -Granularity Hourly -Force -CloudName1 $info.CloudName
