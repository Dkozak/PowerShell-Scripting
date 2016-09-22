
Login-AzureRmAccount

# Enable vnet peering 
Register-AzureRmProviderFeature -FeatureName AllowVnetPeering -ProviderNamespace Microsoft.Network 
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network

# Get vnet properties
$vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName_1
$vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName_2

# Create link between vnets
Add-AzureRmVirtualNetworkPeering -name $peeringName_1 -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet2.id
Add-AzureRmVirtualNetworkPeering -name $peeringName_2 -VirtualNetwork $vnet2 -RemoteVirtualNetworkId $vnet1.id