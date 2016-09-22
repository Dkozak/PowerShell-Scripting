
Login-AzureRmAccount

# Getting alle de the information about the current Nic
$Nic = Get-AzureRmNetworkInterface -ResourceGroupName $rgName -Name $NicName

# Get information about the new subnet of the virtual machine
$NewSubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName) -Name $SubnetName

# Defining the new subnet and set the new properties
$Nic.IpConfigurations[0].Subnet = $NewSubnet
Set-AzureRmNetworkInterface -NetworkInterface $Nic