Set-ExecutionPolicy Bypass -Force
Install-Module -Name OMSIngestionAPI -Force
Install-Module -Name AzureRM.OperationalInsights -Force
Import-Module C:\AZSAdminOMSInt\AzureStack-Tools-vnext\Infrastructure\AzureStack.Infra.psm1 -Force

#OMS Authentication

$info = Get-Content -Raw -Path "C:\AZSAdminOMSInt\info.txt" | ConvertFrom-Json
$Username = $info.AzureUsername
$Password = Get-Content "C:\AZSAdminOMSInt\azpassword.txt" | ConvertTo-SecureString
$Credential=New-Object PSCredential($UserName,$Password)
$OMSWorkspaceName = $info.omsWorkspaceName
$OMSRGName = $info.omsResourceGroup
$SubscriptionIDforOMS = $info.AzureSubscription

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


##############################################################################################################
# Get Data via PS for Cloud 2
Add-AzureRMEnvironment -Name "$cloudName2" -ArmEndpoint $AzureStackAdminEndPoint
Login-AzureRmAccount -EnvironmentName $cloudName2 -Credential $Credential2


##Get Alerts
$AllAlerts2= @(Get-AzsAlert -Location $location2| where-object {$_.state -eq "$State2"})

##Get Stamp Version
$version2=Get-AzsUpdateLocation -Location $location2
$currentversion2=$version2.currentversion
$ustate2=$version2.State

#Get ScaleUnit Data
$AllScaleUnits2=Get-AzSScaleUnitNode -Location $location2


##Get Capacity Data
$usage2=Get-AzsLocationCapacity -location $location2
$metrics2=$usage2.UsageMetrics
$memory2=$metrics2|where {$_.name -eq "physical memory"}
$usedmemory2=$memory2.metricsValue|where {$_.name -eq "used"}
$usedmem2=$usedmemory2.value
$disk2=$metrics2|where {$_.name -eq "physical storage"}
$usedisk2=$disk2.metricsValue|where {$_.name -eq "used"}
$used2=$usedisk2.value


$availmemory2=$memory2.metricsValue|where {$_.name -eq "available"}
$availmem2=$availmemory2.value

$availabledisk2=$disk2.metricsValue|where {$_.name -eq "available"}
$availdisk2=$availabledisk2.value


$IPPool2=$metrics2|where {$_.name -eq "public ip address pools"}
$usedIPPool2=$IPPool2.metricsValue|where {$_.name -eq "used"}
$usedIP2=$usedIPPool2.value
$availIPPool2=$IPPool2.metricsValue|where {$_.name -eq "available"}
$availIP2=$availIPPool2.value


##Get ResourceProvider Health
$RP2=Get-AzsResourceProviderHealths -Location $location2


##Get InfraStructureRole Healths
$Role2=Get-AzsInfrastructureRoleHealths -Location $location2

#Login Azure Cloud for OMS 
Login-AzureRmAccount -Credential $Credential -SubscriptionId $SubscriptionIDforOMS

# get workspace key
$wskey = Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $OMSRGName -Name $OMSWorkspaceName
# get workspace
$ws = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $OMSRGName -Name $OMSWorkspaceName



$MASTest = @()
    $MASData = New-Object psobject -Property @{
        Type = 'Capacity';
        Location = $Location2;
        CloudName = $cloudName2;
        Version = $currentversion2;
        State = $uState2;

        DiskUsed = $used2;
        MemoryUsed = $usedmem2;

        DiskAvail = $availdisk2;
        MemoryAvail = $availmem2;
        IPPoolUsed = $usedIP2;
        IPPoolAvail = $availIP2;
        DeploymentGuid = $deploymentGuid;
        TimeStamp = (Get-Date).ToUniversalTime();
    }

if ( $AllAlerts2.count -gt 1) {    
   
    For ($i=0; $i -lt $AllAlerts2.Length; $i++) {

        $MASRP = New-Object psobject -Property @{
            Type = 'AzureStackAlerts';
            CloudName = $cloudName2;
            Alerts = $AllAlerts2[$i].Title;
            AlertsSeverity = $AllAlerts2[$i].Severity;
            AlertsImpactedResource =$AllAlerts2[$i].ImpactedResourceDisplayName;
            AlertsRemediation = $AllAlerts2[$i].Remediation[0].Text;
            AlertsRemediationLength = $AllAlerts2[$i].Remediation.Length;
            AlertsDescription = $AllAlerts2[$i].Description[0].Text;
            FaultTypeId = $AllAlerts2[$i].FaultTypeId;
            AlertId = $AllAlerts2[$i].AlertId;
            TimeStamp = (Get-Date).ToUniversalTime();

        }

        $MASTest += $MASRP
    }
   
}  elseif ($AllAlerts2 -is [Array] -eq $false) { 

    $MASRP = New-Object psobject -Property @{
        Type = 'AzureStackAlerts';
        CloudName = $cloudName2;
        Alerts = $AllAlerts2[0].Title;
        AlertsSeverity = $AllAlerts2[0].Severity;
        AlertsImpactedResource =$AllAlerts2[0].ImpactedResourceDisplayName;
        AlertsRemediation = $AllAlerts2[0].Remediation[0].Text;
        AlertsDescription = $AllAlerts2[0].Description[0].Text;
        FaultTypeId = $AllAlerts2[0].FaultTypeId;
        AlertId = $AllAlerts2[0].AlertId;
        TimeStamp = (Get-Date).ToUniversalTime();

    }

    $MASTest += $MASRP

} else {
    Write-Host "No Alerts From " + $CloudName2
}

#Add ScaleUnit Data to JSON File
if ($AllScaleUnits2-is [Array]) {    
   
    For ($i=0; $i -lt $AllScaleUnits2.Length; $i++) {


            $ScaleUnit2= $AllScaleUnits2[$i]
            $ScaleUnitNodeStatusValue2=$ScaleUnit2.Properties.ScaleUnitNodeStatus
           
        $MASSUNode = New-Object psobject -Property @{
            Type = 'ScaleUnitNode';
            CloudName = $cloudName2;
            ScaleUnitNodeName = $AllScaleUnits2[$i].Name;
            ScaleUnitNodeLocation = $AllScaleUnits2[$i].Location;
            ScaleUnitNodeOperationalStatus = $ScaleUnitNodeStatusValue2;
            TimeStamp = (Get-Date).ToUniversalTime();
           
        }

        $MASTest += $MASSUNode
    }
   
}  elseif ($AllScaleUnits2) { 
            $ScaleUnit2= $AllScaleUnits2[0]
            $ScaleUnitNodeStatusValue2=$ScaleUnit2.Properties.ScaleUnitNodeStatus
            

    $MASSUNode = New-Object psobject -Property @{
            Type = 'ScaleUnitNode';
            CloudName = $cloudName2;
            ScaleUnitNodeName = $AllScaleUnits2[0].Name;
            ScaleUnitNodeLocation = $AllScaleUnits2[0].Location;
            ScaleUnitNodeOperationalStatus = $ScaleUnitNodeStatusValue2;
           TimeStamp = (Get-Date).ToUniversalTime();
    }

    $MASTest +=  $MASSUNode

} else {
    Write-Host "No Nodes from " + $CloudName2
}
  
For ($i=0; $i -lt $RP2.Length; $i++) {
    
    $MASRP = New-Object psobject -Property @{
        Type = 'ResourceProvider';
        ResourceProvider = $RP2.get($i).DisplayName.ToString()
        ResourceProviderHealths = $RP2.get($i).HealthState.ToString()
        CloudName = $cloudName2;
        TimeStamp = (Get-Date).ToUniversalTime();
    }

    $MASTest += $MASRP

}

 For ($i=0; $i -lt $Role2.Length; $i++) {
    
    $MASROLE = New-Object psobject -Property @{
        Type = 'InfraRoles';
        InfrastructureRole = $Role2.get($i).ResourceName.ToString()
        InfrastructureRoleHealths = $Role2.get($i).HealthState.ToString()
        CloudName = $cloudName2;
       TimeStamp = (Get-Date).ToUniversalTime();
    }

    $MASTest += $MASROLE

}

$MASTest += $MASData
$MASJson = ConvertTo-Json -InputObject $MASTest
$Timestamp = "TimeStamp"

Write-Output $MASJson
$logType = 'AzureStack'
#Upload JSON to OMS
Send-OMSAPIIngestionFile -customerId $ws.CustomerId -sharedKey $wskey.PrimarySharedKey -body $MASJson -logType $logType -TimeStampField $Timestamp

 
