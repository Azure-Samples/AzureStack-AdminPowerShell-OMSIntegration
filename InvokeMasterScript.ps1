Cd\

Set-ExecutionPolicy -ExecutionPolicy Unrestricted

.\MasterScript.ps1 `
    -DeploymentGuid "<Replace with your DeploymentGUID, eg..cc7a4584-30c3-4161-b717-053f9ca7cc65>" `
    -OmsWorkspaceID "<Replace with your OMS Workspace ID found on the log analytics settings>" `
    -OMSSharedKey "<Replace with your OMS Workspace Shared Key found on the log analytics settings>" `
    -azureStackAdminUsername "<replace with your service admin account to access the admin portal/apis>" `
    -azureStackAdminPassword "<replace with your service admin password>" `
    -CloudName "<Replace with your Cloud Name, this is how many data points are pivoted in the views>" `
    -Region "<replace with your region name specified in deployment>" `
    -Fqdn "<replace with your FQDN which follows the region name in your URL, eg.. azurestack.corp.microsoft.com>" `
    -OEM "<replace with your hardware vendor name>" 