Function CreateSqlSrv
{
    Param(
        [String]$sqlServerName,
        [String]$sqluser,
        [String]$sqlpwd,
        [String]$resourceGroupName,
        [String]$sqlLocation,
        [String]$keyVaultName,
        [String]$sqlpwdSecretName
    )

        
    Write-Host "Create Azure SQL Server - $sqlServerName" 
    $sqlPassword = ConvertTo-SecureString -String $sqlpwd -AsPlainText -Force
    $sqlcredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqluser,  $sqlPassword

    New-AzSqlServer -ResourceGroupName $resourceGroupName `
        -Location $sqlLocation `
        -ServerName $sqlServerName `
        -ServerVersion "12.0" `
        -SqlAdministratorCredentials $sqlcredential 

    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $sqlServerName -AllowAllAzureIPs

    Write-Host "INFO" "Prepare to add Azure SQL Server Firewall Rule - Allow Setup Agent Client IP"
    $ipaddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
    Write-Host "Current Agent IP Address = $ipaddress"

    $nowdate = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
    $firewallRuleName = "ClientIPAddress_"+$nowdate
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $sqlServerName -FirewallRuleName $firewallRuleName `
        -StartIpAddress $ipaddress -EndIpAddress $ipaddress -ErrorAction Stop

    Write-Host "Save sql password to key vault"
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $sqlpwdSecretName -SecretValue $sqlPassword
}




Function CreateSqlDb
{
    Param(
        [String]$sqlServerName,
        [String]$sqlDatabaseName,
        [String]$resourceGroupName
    )
    Write-Host "Create Azure SQL Database - $sqlDatabaseName" 
    New-AzSqlDatabase -ResourceGroupName $resourceGroupName  `
        -ServerName $sqlServerName `
        -DatabaseName $sqlDatabaseName `
        -Edition "GeneralPurpose" `
        -Vcore 1 `
        -ComputeGeneration "Gen5" `
        -ComputeModel Serverless
}




Function ExecuteSql
{
    Param(
        [String]$sqlServerName,
        [String]$sqlServerDomain,
        [String]$sqlDatabaseName,
        [String]$resourceGroupName,
        [String]$sqluser,
        [String]$keyVaultName,
        [String]$sqlpwdSecretName,
        [String]$sqlScriptFile
    )
    

    #Before using Invoke-Sqlcmd, will need to install SqlServer module
    # Write-Host "INFO" "Install-Module SqlServer"
    # Install-Module -Name SqlServer -AllowClobber -Scope CurrentUser -Force -ErrorAction Stop

    #Before registry operation, Add SQL server Firewall Rule - Allow Setup Agent Client IP
    Write-Host "INFO" "Prepare to add Azure SQL Server Firewall Rule - Allow Setup Agent Client IP"
    $ipaddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
    Write-Host "Current Agent IP Address = $ipaddress"

    $nowdate = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
    $firewallRuleName = "ClientIPAddress_"+$nowdate
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $sqlServerName -FirewallRuleName $firewallRuleName `
        -StartIpAddress $ipaddress -EndIpAddress $ipaddress -ErrorAction Stop


    $sqlpwd = (Get-AzKeyVaultSecret -vaultName $keyVaultName -name $sqlpwdSecretName).SecretValueText


    $sqlsrvFullName = $sqlServerName+"."+$sqlServerDomain
    Write-Host "INFO" "server full name: $sqlsrvFullName"

    Invoke-Sqlcmd -ServerInstance $sqlsrvFullName -Database $sqlDatabaseName `
        -Username $sqluser -Password $sqlpwd -InputFile $sqlScriptFile `
        -ErrorAction Stop -ConnectionTimeOut 120 | Format-Table
    Write-Host "INFO" "Run Sql successfully."

    Write-Host "INFO" "Remove Azure SQL Server Firewall Rule - Allow Setup Agent Client IP"
    Remove-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $sqlServerName -FirewallRuleName $firewallRuleName -ErrorAction Stop

}

Export-ModuleMember -Function "CreateSqlSrv"
Export-ModuleMember -Function "CreateSqlDb"
Export-ModuleMember -Function "ExecuteSql"