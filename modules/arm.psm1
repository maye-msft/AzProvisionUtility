
Function DeployByARM
{
    Param(
        [String]$resourceGroupName,
        [String]$deploymentName,
        [String]$templateFile,
        [String]$templateParameterFile
    )

        
    Write-Host "Create resource with arm - $deploymentName" 
    Write-Host "resource Group Name - $resourceGroupName" 
    Write-Host "template file - $templateFile" 
    Write-Host "param file - $templateParameterFile" 


    New-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $templateParameterFile
}

Export-ModuleMember -Function "DeployByARM"