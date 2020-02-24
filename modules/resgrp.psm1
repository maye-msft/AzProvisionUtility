Function CreateResourceGroup
{
    Param(
        [String]$resourceGroupName,
        [String]$location
    )
    Write-Host "Start to create resource group $resourceGroupName"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
}

Export-ModuleMember -Function "CreateResourceGroup"