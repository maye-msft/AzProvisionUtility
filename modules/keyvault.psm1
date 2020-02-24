Function CreateKeyVault
{
    Param(
        [String]$keyVaultName,
        [String]$resourceGroupName,
        [String]$location,
        [String]$applicationId
    )

    Write-Host "Create Azure KeyVault - $keyVaultName" 
    New-AzKeyVault -Name $keyVaultName -ResourceGroupName $resourceGroupName -Location $location

    #Grant "Get,Set,List" permission to Azure DevOps pipeline (need service principal app id) to access the new Key Vault
    Set-AzKeyVaultAccessPolicy -resourceGroupName "$resourceGroupName" -VaultName "$keyVaultName" `
    -servicePrincipalName "$applicationId" -PermissionsToSecrets get,set,list

    Write-Host "Set test secret"
    $testValue = ConvertTo-SecureString -String 'testValue' -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'testKey' -SecretValue $testValue

    Write-Host "Get test secret"
    Write-Host (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name 'testKey').SecretValueText
}




Function SetSecretFromKeyVault
{
    Param(
        [String]$keyVaultName,
        [String]$key,
        [String]$value
    )

    Write-Host "Set secret"
    $val = ConvertTo-SecureString -String $value -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $key -SecretValue $val
}



Function GetSecretFromKeyVault
{
    Param(
        [String]$keyVaultName,
        [String]$key
    )
    Write-Host "Get secret"
    return (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $key).SecretValueText
}

Export-ModuleMember -Function "CreateKeyVault"
Export-ModuleMember -Function "SetSecretFromKeyVault"
Export-ModuleMember -Function "GetSecretFromKeyVault"