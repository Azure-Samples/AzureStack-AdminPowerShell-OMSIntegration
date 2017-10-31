<#
    .Synopsis
    Returns a hashtable mapping subscriptionIDs to tenants (e.g. tenant1@contoso.onmicrosoft.com)
    .DESCRIPTION
    Long description
    .EXAMPLE
    Get-AllCurrentSubscriptions -Credential $adminCreds -AADDomain 'contosoupoload.onmicrosoft.com'
#>
function Get-AllCurrentSubscriptions {
    Param(
        [Parameter (Mandatory = $true)]
        [PSCredential]
        $Credential,
        [Parameter (Mandatory = $true)]
        [string]
        $AADDomain,
        [Parameter (Mandatory = $false)]
        [string]
        $AzureStackDomain = 'azurestack.external',
        [Parameter (Mandatory = $false)]
        [string]
        $Region = 'local'
    )
    
    #get auth metadata and acquire token for REST call
    $api = 'adminmanagement'
    $uri = 'https://{0}.{1}.{2}/metadata/endpoints?api-version=1.0' -f $api, $Region, $AzureStackDomain
    $endpoints = (Invoke-RestMethod -Uri $uri -Method Get)
    $activeDirectoryServiceEndpointResourceId = $endpoints.authentication.audiences[0]
    $loginEndpoint = $endpoints.authentication.loginEndpoint
    $authority = $loginEndpoint + $AADDomain + '/'
    $powershellClientId = '0a7bdc5c-7b57-40be-9939-d4c5fc7cd417'

    #region Auth
    $adminToken = Get-AzureStackToken `
        -Authority $authority `
        -Resource $activeDirectoryServiceEndpointResourceId `
        -AadTenantId $AADDomain `
        -ClientId $powershellClientId `
        -Credential $Credential
  
    if (!$adminToken) {
        Return
    }
    #endregion

    #Setup REST call variables
    $headers = @{ Authorization = (('Bearer {0}' -f $adminToken)) }
    $armEndpoint = 'https://{0}.{1}.{2}' -f $api, $Region, $AzureStackDomain

    #Get default subscription ID
    $uri = $armEndpoint + '/subscriptions?api-version=2015-01-01'
    $result = Invoke-RestMethod -Method GET -Uri $uri  -Headers $headers
    $subscription = $result.value[0].subscriptionId

    #build tenant listing uri
    $uri = $armEndpoint + '/subscriptions/{0}/providers/Microsoft.Subscriptions.Admin/subscriptions?api-version=2015-11-01' -f $subscription

    $result = Invoke-RestMethod -Method GET -Uri $uri  -Headers $headers -ErrorVariable RestError -Verbose

    $subTenantHash = @{}
    $result.value | ForEach-Object {
        $subTenantHash.Add($_.subscriptionId, $_.owner)
    }

    return $subTenantHash
}