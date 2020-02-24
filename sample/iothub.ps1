CreateIotHub `
    -resourceGroupName  $args[0]`
    -iotHubName  $args[1] `
    -iotHubLocation $args[2]


CreateIotHubDevice `
    -iotHubName $args[1] `
    -deviceName $args[3]`
    -applicationId $args[4] `
    -applicationSecret $args[5] `
    -tenantId $args[6] `
    -cloud $args[7]