function Get-DeploymentGuid
{
    Import-Module C:\CloudDeployment\ECEngine\EnterpriseCloudEngine.psd1 -ErrorAction Stop
    $engine = New-Object CloudEngine.Engine.DefaultECEngine                 
    $roles = $engine.GetRolesPublicInfo()  
   
    $bareMetalRoleDefinition = $roles["BareMetal"].PublicConfiguration
    $deploymentGuid = $bareMetalRoleDefinition.PublicInfo.DeploymentGuid

    return $deploymentGuid
}

$deploymentGuid = Get-DeploymentGuid

@{
    DeploymentGuid  = $deploymentGuid
}
