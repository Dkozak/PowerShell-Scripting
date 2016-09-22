$SourceResourceGoup = ""
$SourceVMName = ""
SourceVMName
Stop-AzureRmVM -ResourceGroupName $SourceResourceGoup -Name $SourceVMName

# Ask for status VM
$vm = Get-AzureRmVM -ResourceGroupName $SourceResourceGoup -Name $SourceVMName -status
$vm.Statuses

# change state of the source vm
# needed for azure to know it's a sysprepd vm
Set-AzureRmVm -ResourceGroupName $SourceResourceGoup -Name $SourceVMName -Generalized

# captuer imag to destionation storage container
$DestinationResurceGroup = ""
$ImageContainerName = ""
$TemplatePrefix = ""

# $FileName = "Yourlocalfilepath\Filename.json"
### OUTPUT = https://YourStorageAccountName.blob.core.windows.net/system/Microsoft.Compute/Images/YourImagesContainer/YourTemplatePrefix-osDisk.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.vhd
# It will be created in the same storage account as that of the original virtual machine.

Save-AzureRmVMImage -ResourceGroupName $DestinationResurceGroup -VMName $SourceVMName -DestinationContainerName $ImageContainerName -VHDNamePrefix $TemplatePrefix = "" # OPTIONAL -Path $FileName

# Preperation

# STORAGE

# NETWORK

$pipName = ""
$rgName = ""
$location = "WestEurope"
$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic

$subnet1Name = ""
$vnetSubnetAddressPrefix = "10.0.0.0/24"
$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $vnetSubnetAddressPrefix

$vnetName = ""
$rgName = ""
$vnetAddressPrefix = "10.0.0.0/16"
$subnetconfig = ""
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetconfig

$nicname = ""
$rgName = ""
$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# VM

#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential
#Get the storage account where the captured image is stored
$storageAccName = ""
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccName

#Set the VM name and size
$vmName = ""
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A1"

#Set the Windows operating system configuration and add the NIC
$computerName = ""
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

#Configure the OS disk to be created from image (-CreateOption fromImage) and give the URL of the captured image VHD for the -SourceImageUri parameter.
#We found this URL in the local JSON template in the previous sections.
$osDiskName = "DC01Test"
$urlOfCapturedImageVhd = "https://YourStorageAccountName.blob.core.windows.net/system/Microsoft.Compute/Images/YourImagesContainer/YourTemplatePrefix-osDisk.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $urlOfCapturedImageVhd -Windows

#Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
