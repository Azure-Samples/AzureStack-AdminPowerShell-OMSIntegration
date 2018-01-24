Cd\


.\MasterScript.ps1 `
    -DeploymentGuid "<Replace with your DeploymentGUID, eg..cc7a4584-30c3-4161-b717-053f9ca7cc65>" `
    -OMSWorkspaceName "<Replace with your OMS Workspace Name>" `
    -OMSResourceGroup "<Replace with your OMS Workspace Azure Resource Group>" `
    -azureStackAdminUsername "<replace with your service admin account to access the admin portal/apis>" `
    -azureStackAdminPassword "<replace with your service admin password>" `
    -azureUsername "<Replace with an Azure Accout with Log Analytics Contributor access role to this Log Analytics instance>" `
    -azurePassword "<Replace with your Azure Account pwd>" `
    -CloudName "<Replace with your Cloud Name, this is how many data points are pivoted in the views>" `
    -Region "<replace with your region name specified in deploymet>" `
    -Fqdn "<replace with your FQDN which follows the region name in your URL, eg.. azurestack.corp.microsoft.com>"  `
    -azureSubscription "<replace with your azure subscription GUID which contains the Log Analytics instance you are integrating with>" 


