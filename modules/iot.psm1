Function CreateIotHub 
{
    Param(
        [String]$resourceGroupName,
        [String]$iotHubName,
        [String]$iotHubLocation
    )

    Write-Host "Create Azure IoT Hub - $iotHubName" 
    New-AzIotHub `
        -ResourceGroupName $resourceGroupName `
        -Name $iotHubName `
        -SkuName S1 -Units 1 `
        -Location $iotHubLocation `
        -ErrorAction Stop

}



Function CreateIotHubDevice 
{
    Param(
        [String]$iotHubName,
        [String]$deviceName,
        [String]$applicationId,
        [String]$applicationSecret,
        [String]$tenantId,
        [String]$cloud
    )
    az cloud set --name $cloud
    az login --service-principal --username $applicationId --password $applicationSecret --tenant $tenantId
    az extension add --name azure-cli-iot-ext
    az iot hub device-identity create --device-id $deviceName --hub-name $iotHubName

}

Export-ModuleMember -Function "CreateIotHub"
Export-ModuleMember -Function "CreateIotHubDevice"