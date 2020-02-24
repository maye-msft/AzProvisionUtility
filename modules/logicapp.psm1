


Function StartLogicApp
{
    Param(
        [String]$resourceGroupName,
        [String]$logicAppName,
        [String]$logicAppTriggerName
    )

        
    Write-Host "Start Logic App - $logicAppName" 
    Start-AzLogicApp -ResourceGroupName "$resourceGroupName" `
        -Name "$logicAppName" -TriggerName "$logicAppTriggerName"
}

Export-ModuleMember -Function "StartLogicApp"
