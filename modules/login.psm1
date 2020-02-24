# login

Function LoginWithUsrPwd
{
    Param(
        [String]$cloud
    )

    Write-Host "Start to Login with user password"
    $creds = Get-Credential
    Connect-AzAccount -Credential $creds -Environment $cloud 
}



Function LoginWithPrincipal 
{
    Param(
        [String]$applicationId,
        [String]$applicationSecret,
        [String]$subscriptionId,
        [String]$tenantId,
        [String]$cloud
    )

    Write-Host "Start to Login with service principal"
    $azureAppId = $applicationId
    $azureAppSecret = ConvertTo-SecureString -String $applicationSecret -AsPlainText -Force
    $azureAppCred = New-Object System.Management.Automation.PSCredential $azureAppId, $azureAppSecret
    Connect-AzAccount -Environment $cloud -ServicePrincipal -SubscriptionId $subscriptionId -TenantId $tenantId -Credential $azureAppCred

}


Export-ModuleMember -Function "LoginWithUsrPwd"
Export-ModuleMember -Function "LoginWithPrincipal"