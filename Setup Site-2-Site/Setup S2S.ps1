# Azure S2S

# Connect to your subscription
Login-AzureRmAccount
$SubscriptionName = Get-AzureRmSubscription 
Select-AzureRmSubscription -SubscriptionName $SubscriptionName.SubscriptionName


# Create a virtual network and a gateway subnet
$Location = "West Europe"
$ResourceGroupName = ""
$GatewaySubnetName = ""
$SubnetName = ""
$VnetName = ""

New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
$GWsubnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name $GatewaySubnetName -AddressPrefix 10.0.0.0/28  	# PREFIX
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix '10.0.1.0/28'			# PREFIX
New-AzureRmVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 10.0.0.0/16 -Subnet $GWsubnet1, $subnet2

# Add your local network gateway
$LocalGatewayName = ""
$LocalGatewayIP = "23.99.221.164" 
$LocalGatewayAddressPrefix = "10.5.51.0/24"

New-AzureRmLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $ResourceGroupName -Location $Location -GatewayIpAddress $LocalGatewayIP -AddressPrefix $LocalGatewayAddressPrefix

# Request a public IP address for the VPN gateway
$GWIPName = ""

$gwpip= New-AzureRmPublicIpAddress -Name $GWIPName  -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

# Create the gateway IP addressing configuration
$GWIPconfigName = ""

$vnet = Get-AzureRmVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroupName
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $GatewaySubnetName -VirtualNetwork $vnet
$gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfigName -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id 

# Create the virtual network gateway
$GatewayName = ""

New-AzureRmVirtualNetworkGateway -Name $GatewayName -ResourceGroupName $ResourceGroupName -Location $Location -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard

# Configure your VPN device
Get-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $ResourceGroupName

#  Create the VPN connection
$ConnectionName = ""

$gateway1 = Get-AzureRmVirtualNetworkGateway -Name $GatewayName -ResourceGroupName $ResourceGroupName
$local = Get-AzureRmLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $ResourceGroupName
$SharedKey = ""

New-AzureRmVirtualNetworkGatewayConnection -Name $$ConnectionName -ResourceGroupName $ResourceGroupName -Location $Location -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local -ConnectionType IPsec -RoutingWeight 10 -SharedKey $SharedKey

# verify your connection 
Get-AzureRmVirtualNetworkGatewayConnection -Name $ConnectionName -ResourceGroupName $ResourceGroupName -Debug