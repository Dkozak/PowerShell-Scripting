# Create VM from existing uploaded disk



$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic

$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $vnetSubnetAddressPrefix

$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetconfig

$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

#Enter a new username and password in the pop-up for the following
$cred = Get-Credential

#Get the storage account where the uploaded image is stored
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccName

#Set the VM name and size
#Use "Get-Help New-AzureRmVMConfig" to know the available options for -VMsize
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A4"

#Set the Windows operating system configuration and add the NIC
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

#Configure the OS disk to be created from image (-CreateOption fromImage) and give the URL of the uploaded image VHD for the -SourceImageUri parameter
#You can find this URL in the result of the Add-AzureRmVhd cmdlet above
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $urlOfUploadedImageVhd -Windows

#Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm