#Login-AzureRmAccount
Get-AzureRmRoleDefinition -Name "Virtual Machine Contributor" | ConvertTo-Json | Out-File c:\Temp\Roles.json
New-AzureRmRoleDefinition -InputFile C:\Temp\Roles.json