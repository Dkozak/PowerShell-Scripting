# Forced tunneling
# https://azure.microsoft.com/en-us/documentation/articles/vpn-gateway-forced-tunneling-rm/

$ResourcegroupName = "";
$RouteTabelName = ""
$VNETName = ""
$SubnetName1 = ""
$SubnetName2 = ""


# Create the route table and route rule.
New-AzureRmRouteTable –Name $RouteTabelName -ResourceGroupName $ResourcegroupName –Location "West Europe"
$rt = Get-AzureRmRouteTable –Name $RouteTabelName -ResourceGroupName $ResourcegroupName 

Add-AzureRmRouteConfig -Name "DefaultRoute" -AddressPrefix "0.0.0.0/0" -NextHopType VirtualNetworkGateway -RouteTable $rt


Set-AzureRmRouteTable -RouteTable $rt

# Associate the route table to the Midtier and Backend subnets.
$vnet = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $ResourcegroupName

# for each subnet apply routing tabel to subnet
Set-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName1 -VirtualNetwork $vnet -AddressPrefix "10.1.1.0/24" -RouteTable $rt
Set-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName2 -VirtualNetwork $vnet -AddressPrefix "10.1.2.0/24" -RouteTable $rt


Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
