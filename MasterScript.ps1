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
    [Parameter( Mandatory = $true)]
    [string] $DeploymentGuid,
    [Parameter(Mandatory = $true)]
    [string] $OMSWorkspaceID,
    [Parameter(Mandatory = $true)]
    [string] $OMSSharedKey,
    [Parameter(ParameterSetName='AdminAccount',Mandatory = $true)]
    [string] $azureStackAdminUsername,
    [Parameter(ParameterSetName='AdminAccount',Mandatory = $true)]
    [string] $azureStackAdminPassword,
    [Parameter(Mandatory = $true)]
    [string] $CloudName,
    [Parameter(Mandatory = $true)]
    [string] $Region,
    [Parameter(Mandatory = $true)]
    [string] $Fqdn,
    [Parameter(Mandatory = $true)]
    [string] $Oem,
    [Parameter(ParameterSetName='CertSPN',Mandatory = $true)]
    [string] $CertificateThumbprint,
    [Parameter(ParameterSetName='CertSPN',Mandatory = $true)]
    [string] $ApplicationId,
    [Parameter(ParameterSetName='CertSPN',Mandatory = $true)]
    [Parameter(ParameterSetName='AdminAccount',Mandatory = $false)]
    [string] $TenantId
   
)
if($pscmdlet.ParameterSetName -eq "AdminAccount")
{
    $azureStackAdminPasswordSecureString = $azureStackAdminPassword | ConvertTo-SecureString -Force -AsPlainText
}

cd c:\

# Set TLS 1.2 (3072) as that is the minimum required by Chocolatey.org.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072


# install git
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# refresh the PATH to recognize "choco" command
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
choco install git.install -y
# refresh the PATH to recognize git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
git clone "https://github.com/Azure-Samples/AzureStack-AdminPowerShell-OMSIntegration.git" C:\AZSAdminOMSInt


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


Switch($pscmdlet.ParameterSetName)
{
    "AdminAccount" {
        # store data required by scheduled task to use AdminAccount in files. 
        $info = @{
            ParameterSet = $pscmdlet.ParameterSetName;
            DeploymentGuid = $DeploymentGuid;
            CloudName = $CloudName;
            Region = $Region;
            Fqdn = $Fqdn;
            OmsWorkspaceID = $OMSWorkspaceID;
            OmsSharedKey = $OMSSharedKey;
            Oem = $Oem;
            AzureStackAdminUsername = $azureStackAdminUsername;
            
        }
        if($TenantId)
        {#If a TenantId was provided add it to the data that will be stored
            $info.Add("TenantId", $TenantId)
        }
        #store passwords in txt files. 
        $passwordText = $azureStackAdminPasswordSecureString | ConvertFrom-SecureString
        Set-Content -Path "C:\AZSAdminOMSInt\azspassword_$CloudName.txt" -Value $passwordText
        }

    "CertSPN" {
        # store data required by scheduled task to use CertSPN in files. 
        $info = @{
            ParameterSet = $pscmdlet.ParameterSetName;
            DeploymentGuid = $DeploymentGuid;
            CloudName = $CloudName;
            Region = $Region;
            Fqdn = $Fqdn;
            OmsWorkspaceID = $OMSWorkspaceID;
            OmsSharedKey = $OMSSharedKey;
            Oem = $Oem;
            CertificateThumbprint = $CertificateThumbprint;
            ApplicationId = $ApplicationId;
            TenantId = $TenantId;
        }
    }
}

$infoJson = ConvertTo-Json $info
Set-Content -Path "C:\AZSAdminOMSInt\info_$CloudName.txt" -Value $infoJson


#Download Azure Stack Tools VNext
cd c:\AZSAdminOMSInt
invoke-webrequest https://github.com/Azure/AzureStack-Tools/archive/vnext.zip -OutFile vnext.zip
expand-archive vnext.zip -DestinationPath . -Force

# schedule windows scheduled task
cd C:\AZSAdminOMSInt
& .\schedule_usage_upload.ps1 -CloudName $CloudName
