


$currentPath = Convert-Path .


Import-Module "$currentPath/modules/arm.psm1"

$subscriptionId = $args[0]

$resgrp = $args[1]
$storeProcedureName = $args[2]
$logicAppName = $args[3]
$logicAppLocation = $args[4]
$sqlServerName = $args[5]
$sqlServerDomain = $args[6]
$sqlDatabaseName = $args[7]  
$sqluser = $args[8]  
$keyVaultName = $args[9]
$sqlpwdSecretName = $args[10]  






$sqlpwd = GetSecretFromKeyVault `
    -keyVaultName $keyVaultName `
    -key $sqlpwdSecretName


$connString =  "Driver={ODBC Driver 13 for SQL Server};Server=tcp:$sqlServerName.$sqlServerDomain,1433;Database=$sqlDatabaseName;Uid=$sqluser;Pwd=$sqlpwd;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"

$connectionTemplateDef = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "connections_sql_name": {
            "defaultValue": "$logicAppName-sqlconn",
            "type": "string"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Web/connections",
            "apiVersion": "2016-06-01",
            "name": "[parameters('connections_sql_name')]",
            "location": "$logicAppLocation",
            "properties": {
                "displayName": "[concat(parameters('connections_sql_name'), '$sqlDatabaseName $sqlServerName.$sqlServerDomain')]",
                "customParameterValues": {},
                "api": {
                    "id": "[concat('/subscriptions/$subscriptionId/providers/Microsoft.Web/locations/$logicAppLocation/managedApis/', 'sql')]"
                },
                "parameterValues": {
                    "sqlConnectionString": "$connString",
                    "server":"$sqlServerName.$sqlServerDomain",
                    "database":"$sqlDatabaseName",
                    "username":"$sqluser",
                    "password":"$sqlpwd"
                    
                }
            }
        }
    ]
}
"@

$connectionParamDef = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "connections_sql_name": {
            "value": "$logicAppName-sqlconn",
        }
    }
}
"@

$logicAppTemplateDef = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workflows_test2_name": {
            "defaultValue": "$logicAppName",
            "type": "String"
        },
        "connections_sql_1_externalid": {
            "defaultValue": "/subscriptions/$subscriptionId/resourceGroups/$resgrp/providers/Microsoft.Web/connections/$logicAppName-sqlconn",
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Logic/workflows",
            "apiVersion": "2017-07-01",
            "name": "[parameters('workflows_test2_name')]",
            "location": "$logicAppLocation",
            "properties": {
                "state": "Enabled",
                "definition": {
                    "`$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {
                        "`$connections": {
                            "defaultValue": {},
                            "type": "Object"
                        }
                    },
                    "triggers": {
                        "Recurrence": {
                            "recurrence": {
                                "frequency": "Hour",
                                "interval": 1
                            },
                            "type": "Recurrence"
                        }
                    },
                    "actions": {
                        "Execute_stored_procedure_(V2)": {
                            "runAfter": {},
                            "type": "ApiConnection",
                            "inputs": {
                                "body": {
                                },
                                "host": {
                                    "connection": {
                                        "name": "@parameters('`$connections')['sql']['connectionId']"
                                    }
                                },
                                "method": "post",
                                "path": "/v2/datasets/@{encodeURIComponent(encodeURIComponent('default'))},@{encodeURIComponent(encodeURIComponent('default'))}/procedures/@{encodeURIComponent(encodeURIComponent('$storeProcedureName'))}"
                            }
                        }
                    },
                    "outputs": {}
                },
                "parameters": {
                    "`$connections": {
                        "value": {
                            "sql": {
                                "connectionId": "[parameters('connections_sql_1_externalid')]",
                                "connectionName": "$logicAppName-sqlconn",
                                "id": "/subscriptions/$subscriptionId/providers/Microsoft.Web/locations/$logicAppLocation/managedApis/sql"
                            }
                        }
                    }
                }
            }
        }
    ]
}
"@

$logicAppParamDef = @"
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workflows_test2_name": {
            "value": "$logicAppName"
        },
        "connections_sql_1_externalid": {
            "value": "/subscriptions/$subscriptionId/resourceGroups/$resgrp/providers/Microsoft.Web/connections/$logicAppName-sqlconn"
        }
    }
}
"@


$currentPath = Convert-Path .
New-Item -Path "$currentPath/tmp" -Type Directory -Force

$connectionTemplateDefPath = "$currentPath/tmp/"+$logicAppName+"_conn_template.json "
Set-Content -Path $connectionTemplateDefPath -Value $connectionTemplateDef

$connectionParamDefPath = "$currentPath/tmp/"+$logicAppName+"_conn_param.json "
Set-Content -Path $connectionParamDefPath -Value $connectionParamDef

$logicAppTemplateDefPath = "$currentPath/tmp/"+$logicAppName+"_template.json "
Set-Content -Path $logicAppTemplateDefPath -Value $logicAppTemplateDef

$logicAppParamDefPath = "$currentPath/tmp/"+$logicAppName+"_param.json "
Set-Content -Path $logicAppParamDefPath -Value $logicAppParamDef





DeployByARM `
    -resourceGroupName $resgrp `
    -deploymentName $logicAppName `
    -templateFile $connectionTemplateDefPath `
    -templateParameterFile $connectionParamDefPath

DeployByARM `
    -resourceGroupName $resgrp `
    -deploymentName $logicAppName `
    -templateFile $logicAppTemplateDefPath `
    -templateParameterFile $logicAppParamDefPath