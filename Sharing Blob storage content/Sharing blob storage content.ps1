 
#Login-AzureRmAccount
 
<#
Example : 
#>
$resourcegroupName = ""
$storageAccountName = ""
$ContainerName = "" 
$TimeDuration = 4 
$FileName = ""
$blobUri = ""
$Permissions = ""
 
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourcegroupName -Name $storageAccountName; 
$key = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroupName -Name $storageAccount.StorageAccountName).Key1
$context = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $key
$StartTime = Get-Date
$endTime = $StartTime.AddHours($TimeDuration)
$SASToken = New-AzureStorageBlobSASToken -Container $ContainerName -Blob $FileName -Permission $Permissions -StartTime $StartTime -ExpiryTime $endTime -Context $context
$ConnectionUri = $blobUri + $SASToken

write-host $ConnectionUri -ForegroundColor Yellow
