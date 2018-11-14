<#
.Synopsis

The script that gets called by the ARM template when it deploys a custom script extension. 
It sets up a scheduled task to upload usage data to OMS. 

.DESCRIPTION

It Sets up git and download repository containing the necessary scripts, stores necessary
information onto the host and then sets up a windows scheduled task to upload usage data 
daily.  

.EXAMPLE
This script is meant to be called from an ARM template. 
.\MasterScript `
    -DeploymentGuid <deployment guid> `
    -OMSWorkspaceID "myomsworkspaceGUID" `
    -OMSSharedKey "myomssharedkeyGUID" `
    -azureStackAdminUsername "serviceadmin@contoso.onmicrosoft.com" `
    -azureStackAdminPassword $Password `
    -CloudName "Cloud#1" `
    -Region "local" `
    -Fqdn "azurestack.external"
    -OEM "HPE"  

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $DeploymentGuid,
    [Parameter(Mandatory = $true)]
    [string] $OMSWorkspaceID,
    [Parameter(Mandatory = $true)]
    [string] $OMSSharedKey,
    [Parameter(Mandatory = $true)]
    [string] $azureStackAdminUsername,
    [Parameter(Mandatory = $true)]
    [string] $azureStackAdminPassword,
    [Parameter(Mandatory = $true)]
    [string] $CloudName,
    [Parameter(Mandatory = $true)]
    [string] $Region,
    [Parameter(Mandatory = $true)]
    [string] $Fqdn,
    [Parameter(Mandatory = $true)]
    [string] $Oem
   
)

$azureStackAdminPasswordSecureString = $azureStackAdminPassword | ConvertTo-SecureString -Force -AsPlainText

cd c:\

# install git
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# refresh the PATH to recognize "choco" command
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
choco install git.install -y
# refresh the PATH to recognize git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
git clone "https://github.com/ashika789/AzureStack-AdminPowerShell-OMSIntegration.git" C:\AZSAdminOMSInt 

# installing powershell modules for azure stack. 
# NuGet required for Set-PsRepository PSGallery.  
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PsRepository PSGallery -InstallationPolicy Trusted
Get-Module -ListAvailable | where-Object {$_.Name -like "Azure*"} | Uninstall-Module
Install-Module -Name AzureRm.BootStrapper -Force
Install-Module -Name AzureRm.Resources -Force
Install-Module -Name AzureStack -Force
Install-Module -Name AzureRM.AzureStackAdmin -Force
Install-Module -Name Azs.Infrastructureinsights.Admin -Force
Install-Module -Name Azs.Update.Admin -Force
Install-Module -Name Azs.Fabric.Admin -Force

# store data required by scheduled task in files. 
$info = @{
    DeploymentGuid = $DeploymentGuid;
    CloudName = $CloudName;
    Region = $Region;
    Fqdn = $Fqdn;
    OmsWorkspaceID = $OMSWorkspaceID;
    OmsSharedKey = $OMSSharedKey;
    AzureStackAdminUsername = $azureStackAdminUsername;
    AzureStackAdminPassword = $azureStackAdminPassword;
    Oem = $Oem;
}

$infoJson = ConvertTo-Json $info
Set-Content -Path "C:\AZSAdminOMSInt\info.txt" -Value $infoJson

#store passwords in txt files. 
$passwordText = $azureStackAdminPasswordSecureString | ConvertFrom-SecureString
Set-Content -Path "C:\AZSAdminOMSInt\azspassword.txt" -Value $passwordText


#Download Azure Stack Tools VNext
cd c:\AZSAdminOMSInt
invoke-webrequest https://github.com/Azure/AzureStack-Tools/archive/vnext.zip -OutFile vnext.zip
expand-archive vnext.zip -DestinationPath . -Force

# schedule windows scheduled task
cd C:\AZSAdminOMSInt
& .\schedule_usage_upload.ps1
