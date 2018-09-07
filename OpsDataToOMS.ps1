Start-Transcript -Path C:\AZSAdminOMSInt\OpsDataToOMS.log
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


##############################################################################################################
# Get Data via PS for Cloud 2
Add-AzureRMEnvironment -Name "$cloudName2" -ArmEndpoint $AzureStackAdminEndPoint
Add-AzureRmAccount -EnvironmentName $cloudName2 -Credential $Credential2


##Get Alerts
$AllAlerts2= @(Get-AzsAlert -Location $location2| where-object {$_.state -eq "$State2"} | Select-Object AlertId, CreatedTimestamp, FaultTypeId, ImpactedResourceDisplayName, Severity, Title)

##Get Stamp Version
$version2=Get-AzsUpdateLocation -Location $location2
$currentversion2=$version2.currentversion
$currentoemversion2=$version2.CurrentOemVersion
$ustate2=$version2.State

#Get ScaleUnit Data
$AllScaleUnits2 = Get-AzSScaleUnitNode -Location $location2 


##Get Capacity Data
$usage2= Get-AzsRegionHealth -location $location2
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
$RP2 = @(Get-AzsRPHealth -Location $location2 | where {$_.healthstate -ne "Unknown"})


##Get InfraStructureRole Healths
$FabricRP = Get-AzsRPHealth -Location $location2 | where{$_.NamespaceProperty -eq "Microsoft.Fabric.Admin"}
$Role2 = Get-AzsRegistrationHealth -Location $location2 -ServiceRegistrationId $FabricRP.RegistrationId | where {$_.healthstate -ne "Unknown"}

$MASTest = @()
    $MASData = New-Object psobject -Property @{
        Type = 'Capacity';
        Location = $Location2;
        CloudName = $cloudName2;
        Version = $currentversion2;
        OEMVersion = $currentoemversion2;
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

 $MASAlerts = @{}

if ($AllAlerts2.count -ge 1) {    
   
    For ($i=0; $i -lt $AllAlerts2.Length; $i++) {

        $MASAlerts = New-Object psobject -Property @{
            Type = 'AzureStackAlerts';
            CloudName = $cloudName2;
            Alerts = $AllAlerts2[$i].Title;
            AlertsSeverity = $AllAlerts2[$i].Severity;
            AlertsImpactedResource =$AllAlerts2[$i].ImpactedResourceDisplayName;
            FaultTypeId = $AllAlerts2[$i].FaultTypeId;
            AlertId = $AllAlerts2[$i].AlertId;
            CreatedTimeStamp = $AllAlerts2[$i].CreatedTimestamp
            TimeStamp = (Get-Date).ToUniversalTime();

        }

        $MASTest += $MASAlerts
    }
   
}  elseif ($AllAlerts2 -is [Array] -eq $false) { 

    $MASAlerts = New-Object psobject -Property @{
        Type = 'AzureStackAlerts';
        CloudName = $cloudName2;
        Alerts = $AllAlerts2[0].Title;
        AlertsSeverity = $AllAlerts2[0].Severity;
        AlertsImpactedResource =$AllAlerts2[0].ImpactedResourceDisplayName;
        FaultTypeId = $AllAlerts2[0].FaultTypeId;
        AlertId = $AllAlerts2[0].AlertId;
        CreatedTimeStamp = $AllAlerts2[0].CreatedTimestamp
        TimeStamp = (Get-Date).ToUniversalTime();

    }

    $MASTest += $MASAlerts

} else {
    Write-Host "No Alerts From " + $CloudName2
}

#Add ScaleUnit Data to JSON File
if ($AllScaleUnits2-is [Array]) {    
   
    For ($i=0; $i -lt $AllScaleUnits2.Length; $i++) {


         
        $MASSUNode = New-Object psobject -Property @{
            Type = 'ScaleUnitNode';
            CloudName = $cloudName2;
            ScaleUnitNodeName = $AllScaleUnits2[$i].Name;
            ScaleUnitNodeLocation = $AllScaleUnits2[$i].Location;
            ScaleUnitNodeOperationalStatus = $AllScaleUnits2[$i].ScaleUnitNodeStatus;
            ScaleUnitNodeandCloudName = $AllScaleUnits2[$i].Name +'_'+ $cloudName2;
            ScaleUnitName = $AllScaleUnits2[$i].ScaleUnitName;
            TimeStamp = (Get-Date).ToUniversalTime();
           
        }

        $MASTest += $MASSUNode
    }
   
}  elseif ($AllScaleUnits2) { 

            

    $MASSUNode = New-Object psobject -Property @{
            Type = 'ScaleUnitNode';
            CloudName = $cloudName2;
            ScaleUnitNodeName = $AllScaleUnits2[0].Name;
            ScaleUnitNodeLocation = $AllScaleUnits2[0].Location;
            ScaleUnitNodeOperationalStatus = $AllScaleUnits2[0].ScaleUnitNodeStatus;
            ScaleUnitNodeandCloudName = $AllScaleUnits2[0].Name +'_'+ $cloudName2;
            ScaleUnitName = $AllScaleUnits2[0].ScaleUnitName;
           TimeStamp = (Get-Date).ToUniversalTime();
    }

    $MASTest +=  $MASSUNode

} else {
    Write-Host "No Nodes from " + $CloudName2
}
  
For ($i=0; $i -lt $RP2.Length; $i++) {
    
    $MASRP = New-Object psobject -Property @{
        Type = 'ResourceProvider';
      ResourceProvider = $RP2[$i].DisplayName
        ResourceProviderHealths = $RP2[$i].HealthState
        CloudName = $cloudName2;
        TimeStamp = (Get-Date).ToUniversalTime();
    }

    $MASTest += $MASRP

}

 For ($i=0; $i -lt $Role2.Length; $i++) {
    
    $MASROLE = New-Object psobject -Property @{
        Type = 'InfraRoles';
        InfrastructureRole = $Role2[$i].ResourceName
        InfrastructureRoleHealths = $Role2[$i].HealthState
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
Send-OMSAPIIngestionFile -customerId $OMSWorkspaceId -sharedKey $OMSSharedKey -body $MASJson -logType $logType -TimeStampField $Timestamp

