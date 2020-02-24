


Function CreateStreamAnalytics
{
    Param(
        [String]$resourceGroupName,
        [String]$asaName,
        [String]$asaLocation
    )

    $streamAnalyticsJobDefinition =
@"
{
    "location": "$asaLocation",
    "properties": {
        "sku": {
            "name": "standard"
        },
        "eventsOutOfOrderPolicy": "adjust",
        "eventsOutOfOrderMaxDelayInSeconds": 10,
        "compatibilityLevel": 1.1
    }
}  
"@


    Write-Host "Create Stream Analytics Job - $asaName" 

    $currentPath = Convert-Path .
    New-Item -Path "$currentPath/tmp" -Type Directory -Force
    
    $jobDefinition = "$currentPath/tmp/JobDefinition.json"
    
    Set-Content -Path $jobDefinition -Value $streamAnalyticsJobDefinition
    
    Write-Host "Job Definition - $jobDefinition" 
    
    New-AzStreamAnalyticsJob `
      -ResourceGroupName $resourceGroupName `
      -File $jobDefinition `
      -Name $asaName `
      -Force

}




Function CreateASAJobQuery
{
    Param(
        [String]$resourceGroupName,
        [String]$streamAnalyticsJobName,
        [String]$streamAnalyticsTransformName,
        [String]$queryFilePath
    )

    $query = Get-Content -Path $queryFilePath -Raw
    Write-Host "Create Stream Analytics Transformation Query $streamAnalyticsTransformName" 

$streamAnalyticsJobTransformationQueryDefinition = @"
{
  "name":"$streamAnalyticsTransformName",
  "type":"Microsoft.StreamAnalytics/streamingjobs/transformations",
  "properties":{
      "streamingUnits":1,
      "script":null,
      "query":"$query"
  }
}
"@

    $currentPath = Convert-Path .
    New-Item -Path "$currentPath/tmp" -Type Directory -Force
    $jobQueryDefinition = "$currentPath/tmp/"+$streamAnalyticsTransformName+"_JobTransformationQueryDefinition.json  "

    Set-Content -Path $jobQueryDefinition -Value $streamAnalyticsJobTransformationQueryDefinition
    New-AzStreamAnalyticsTransformation `
        -ResourceGroupName $resourceGroupName `
        -JobName $streamAnalyticsJobName `
        -File $jobQueryDefinition `
        -Name $streamAnalyticsTransformName -Force
}




Function CreateASAJobOutputSqlDb
{
    Param(
        [String]$resourceGroupName,
        [String]$streamAnalyticsJobName,
        [String]$streamAnalyticsSqlOutputName,
        [String]$sqlServerName,
        [String]$sqlServerDomain,
        [String]$sqlDatabaseName,
        [String]$sqluser,
        [String]$keyVaultName,
        [String]$sqlpwdSecretName,
        [String]$tableName
    )


    
    $sqlSeverSysName = $sqlServerName+"."+$sqlServerDomain

    $sqlpwd = (Get-AzKeyVaultSecret -vaultName $keyVaultName -name $sqlpwdSecretName).SecretValueText

    # create stream analytics blob output
    Write-Host "Create Stream Analytics Blob Output - $streamAnalyticsSqlOutputName" 
$streamAnalyticsJobSQLOutputDefinition = @"
  {
  "properties": {
      "datasource": {
          "type": "Microsoft.Sql/Server/Database",
          "properties": {
              "server": "$sqlSeverSysName",
              "database": "$sqlDatabaseName",
              "user": "$sqluser",
              "password": "$sqlpwd",
              "table": "$tableName"
          }
      }
  },
  "name": "$streamAnalyticsSqlOutputName",
  "type": "Microsoft.StreamAnalytics/streamingjobs/outputs"
}
"@ 


    $currentPath = Convert-Path .
    New-Item -Path "$currentPath/tmp" -Type Directory -Force

    $jobOutputDefinition = "$currentPath/tmp/"+$streamAnalyticsSqlOutputName+"_JobOutputDefinition.json "

    Set-Content -Path $jobOutputDefinition -Value $streamAnalyticsJobSQLOutputDefinition
    New-AzStreamAnalyticsOutput `
        -ResourceGroupName $resourceGroupName `
        -JobName $streamAnalyticsJobName `
        -File $jobOutputDefinition `
        -Name $streamAnalyticsSqlOutputName -Force
}


Function CreateASAJobOutputBlobStorage
{
    Param(
        [String]$resourceGroupName,
        [String]$storageAccountName,
        [String]$storageContainerName,
        [String]$streamAnalyticsJobName,
        [String]$streamAnalyticsBlobOutputName,
        [String]$pathPattern,
        [String]$dateFormat,
        [String]$timeFormat
    )

    

    $storageAccountKey = (Get-AzStorageAccountKey `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName).Value[0]

    # create stream analytics blob output
    Write-Host "Create Stream Analytics Blob Output - $streamAnalyticsBlobOutputName" 
$streamAnalyticsJobBlobOutputDefinition =@"
{
  "properties": {
      "datasource": {
          "type": "Microsoft.Storage/Blob",
          "properties": {
              "storageAccounts": [
                  {
                    "accountName": "$storageAccountName",
                    "accountKey": "$storageAccountKey"
                  }
              ],
              "container": "$storageContainerName",
              "pathPattern": "$pathPattern",
              "dateFormat": "$dateFormat",
              "timeFormat": "$timeFormat"
          }
      },
      "serialization": {
          "type": "Json",
          "properties": {
              "encoding": "UTF8",
              "format": "LineSeparated"
          }
      }
  },
  "name": "$streamAnalyticsBlobOutputName",
  "type": "Microsoft.StreamAnalytics/streamingjobs/outputs"
}
"@



    $currentPath = Convert-Path .
    New-Item -Path "$currentPath/tmp" -Type Directory -Force

    $jobOutputDefinition = "$currentPath/tmp/"+$streamAnalyticsBlobOutputName+"_JobOutputDefinition.json "

    Set-Content -Path $jobOutputDefinition -Value $streamAnalyticsJobBlobOutputDefinition
    New-AzStreamAnalyticsOutput `
    -ResourceGroupName $resourceGroupName `
    -JobName $streamAnalyticsJobName `
    -File $jobOutputDefinition `
    -Name $streamAnalyticsBlobOutputName -Force
}




Function CreateASAJobInputIoTHub
{
    Param(
        [String]$resourceGroupName,
        [String]$iotHubName,
        [String]$streamAnalyticsInputName,
        [String]$iotHubConsumerGroupName,
        [String]$streamAnalyticsJobName
    )

    
    $sharedAccessPolicyName = "iothubowner"


    $iothubKey = Get-AzIotHubKey -ResourceGroupName "$resourceGroupName"  -Name "$iotHubName" `
                        -KeyName "$sharedAccessPolicyName" | ConvertTo-Json | ConvertFrom-Json 


    # create stream analytics input
    $accesspolicykey = $iothubKey.PrimaryKey

    Add-AzIotHubEventHubConsumerGroup -ResourceGroupName "$resourceGroupName" `
                -Name "$iotHubName" -EventHubConsumerGroupName "$iotHubConsumerGroupName"


    Write-Host "Create Stream Analytics Input - $streamAnalyticsInputName" 

$streamAnalyticsJobInputDefinition =@"
{
  "properties": {
      "type": "Stream",
      "datasource": {
          "type": "Microsoft.Devices/IotHubs",
          "properties": {
              "iotHubNamespace": "$iotHubName",
              "sharedAccessPolicyName": "$sharedAccessPolicyName",
              "sharedAccessPolicyKey": "$accesspolicykey",
              "endpoint": "messages/events",
              "consumerGroupName": "$iotHubConsumerGroupName"
              }
      },
      "compression": {
          "type": "None"
      },
      "serialization": {
          "type": "Json",
          "properties": {
              "encoding": "UTF8"
          }
      }
  },
  "name": "$streamAnalyticsInputName",
  "type": "Microsoft.StreamAnalytics/streamingjobs/inputs"
}  
"@

    $currentPath = Convert-Path .
    New-Item -Path $currentPath\tmp -Type Directory -Force

    $jobInputDefinition = "$currentPath/tmp/"+$streamAnalyticsInputName+"_JobInputDefinition.json "

    Set-Content -Path $jobInputDefinition -Value $streamAnalyticsJobInputDefinition

    New-AzStreamAnalyticsInput `
    -ResourceGroupName $resourceGroupName `
    -JobName $streamAnalyticsJobName `
    -File $jobInputDefinition `
    -Name $streamAnalyticsInputName
}




Function StartASAJob
{
    Param(
       [String]$resourceGroupName,
       [String]$streamAnalyticsJobName
    )
    Write-Host "Start Stream Analytics Job - $streamAnalyticsJobName" 

    Start-AzStreamAnalyticsJob `
    -ResourceGroupName $resourceGroupName `
    -Name $streamAnalyticsJobName `
    -OutputStartMode 'JobStartTime'
}




Function StopASAJob
{
    Param(
        [String]$resourceGroupName,
        [String]$streamAnalyticsJobName
    )

    Write-Host "Stop Stream Analytics Job - $streamAnalyticsJobName" 

    Start-AzStreamAnalyticsJob `
    -ResourceGroupName $resourceGroupName `
    -Name $streamAnalyticsJobName 
}

Export-ModuleMember -Function "CreateStreamAnalytics"
Export-ModuleMember -Function "CreateASAJobQuery"
Export-ModuleMember -Function "CreateASAJobInputIoTHub"
Export-ModuleMember -Function "CreateASAJobOutputSqlDb"
Export-ModuleMember -Function "CreateASAJobOutputBlobStorage"
Export-ModuleMember -Function "StartASAJob"
Export-ModuleMember -Function "StopASAJob"