# Upload image to storage account

$ResourceGroupName = ""
$DestinationBlobUri = "<StorageAccountURL>/<BlobContainer>/<TargetVHDName>.vhd"
$LocalPath = ""
Add-AzureRmVhd -ResourceGroupName $ResourceGroupName  -Destination $DestinationBlobUri -LocalFilePath $LocalPath
