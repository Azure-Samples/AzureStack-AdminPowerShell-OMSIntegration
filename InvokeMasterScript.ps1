Cd\

Set-ExecutionPolicy -ExecutionPolicy Unrestricted

.\MasterScript.ps1 `
    -DeploymentGuid "<Replace with your DeploymentGUID, eg..cc7a4584-30c3-4161-b717-053f9ca7cc65>" `
    -OmsWorkspaceID "<Replace with your OMS Workspace ID found on the log analytics settings>" `
    -OMSSharedKey "<Replace with your OMS Workspace Shared Key found on the log analytics settings>" `
    -CloudName "<Replace with your Cloud Name, this is how many data points are pivoted in the views>" `
    -Region "<Replace with your region name specified in deploymet>" `
    -Fqdn "<Replace with your FQDN which follows the region name in your URL, eg.. azurestack.corp.microsoft.com>" `
    -OEM "<Replace with your hardware vendor name>" `
    #Uncomment the below 2 lines if using Admin Credentials to gather data
    #-azureStackAdminUsername "<Replace with your service admin account to access the admin portal/apis>" `
    #-azureStackAdminPassword "<Replace with your service admin password>" 
    #Uncomment the below 3 lines if using a SPN Cert to gather data
    #-CertificateThumbprint "<Replace with the thumbprint of your cert used for SPN>" `
    #-ApplicationId "<Replace with the ClientID of the SPN>" `
    #-TenantId "<Replace with the TenantId for the AzureStack>"



