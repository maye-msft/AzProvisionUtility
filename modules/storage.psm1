Function CreateStorageAccount
{
    Param(
        [String]$resourceGroupName,
        [String]$storageAccountName,
        [String]$location
    )

    Write-Host "Start to create storage account $storageAccountName"

    New-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $storageAccountName `
        -Location $location `
        -SkuName Standard_LRS `
        -Kind Storage
}




Function CreateStorageContainer
{
    Param(
        [String]$resourceGroupName,
        [String]$storageAccountName,
        [String]$storageContainerName
    )

    Write-Host "Start to create storage account $storageContainerName"

    $storageAccount = Get-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $storageAccountName `

    New-AzStorageContainer `
        -Name $storageContainerName `
        -Context $storageAccount.Context
    
}

Export-ModuleMember -Function "CreateStorageAccount"
Export-ModuleMember -Function "CreateStorageContainer"