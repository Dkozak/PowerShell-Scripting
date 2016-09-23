$rgName = ""
$vnetName = ""
$VirtualNetworkGatewayName = ""
$newAddressSpace = ""
$gatewayIpName = ""
$region = ""
$LocalGatewayName = ""
$SharedKey = ""
$ConnectionName = ""

# Prepare the network
function Remove-IHNetworkPeering {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$rgName,
        [Parameter(Mandatory)]
        [string]$vnet
    )
    foreach ($PeeringName in (Get-AzureRmVirtualNetworkPeering -ResourceGroupName $rgName -VirtualNetworkName $vnet.Name)) {
        # THis will remove all peered connections on the network.
        $params = @{
            ResourceGroupName = $PeeringName.ResourceGroupName
            VirtualNetworkName = $PeeringName.VirtualNetworkName
            Name = $PeeringName.Name
        }
        #splat params to command
        Remove-AzureRmVirtualNetworkPeering @params -force
    }
}# Is working
function Set-IHVirtualNetwork {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$rgName,
        [Parameter(Mandatory)]
        [string]$vnetName,
        [string]$newAddressSpace,
        [Parameter(Mandatory)]
        [string]$VirtualNetworkGatewayName
    )
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName

    # Remove all current peerings
    Remove-IHNetworkPeering -rgName $rgName -vnet $vnet

    # Adding new addressspace to the virtual network
    $vnet.AddressSpace.AddressPrefixes = ($vnet.AddressSpace.AddressPrefixes[0]),$newAddressSpace
   
    # Adding Temp subnet
    $bit = (($vnet.AddressSpace.AddressPrefixes[0]).Split('/'))[0].Split(".")
    $TempSubnetSpace = $bit[0] + "." + $bit[1]  + "." + ($bit[2] = ($vnet.Subnets.AddressPrefix).Count)  + "." + $bit[3] + "/24"
    Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name Temp-Subnet -AddressPrefix $TempSubnetSpace.ToString()
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName

    # Move all VM's to Temp Subnet
    $SubNetConfig = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet
    $AllNics = Get-AzureRmNetworkInterface

    while ($null -eq (Get-AzureRmVirtualNetworkSubnetConfig -Name Temp-Subnet -VirtualNetwork $vnet).Id) {
            Write-Output "waiting for azure virtual network subnet config ID"
            Start-Sleep -Seconds 10
    }

    foreach ($Nic in $AllNics) {
        foreach ($SubnetId in $SubNetConfig) {
            if ($Nic.IpConfigurations.Subnet.Id -eq $SubnetId.Id) {
                $Nic.IpConfigurations.Subnet.Id = (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name Temp-Subnet).Id 
                Set-AzureRmNetworkInterface -NetworkInterface $Nic -Verbose            
            }            
        }
        $ID = (Get-AzureRmVirtualNetworkGateway -ResourceGroupName $rgName -Name $VirtualNetworkGatewayName).Id
        # Remove virtual network gateway (will also remove the connections)
        foreach ($GateWayConnection in (Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName $rgName )) {
            if ($GateWayConnection.VirtualNetworkGateway1Text.Replace('"',"") -eq $ID) {
                $GateWayConnection | Remove-AzureRmVirtualNetworkGatewayConnection -force        
            } 
        }
        Remove-AzureRmVirtualNetworkGateway -ResourceGroupName $rgName -Name $VirtualNetworkGatewayName -force
        Write-Verbose -Message "The network is prepared" -Verbose
        $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName
        return $vnet
    }   
}# Is Should be working
function Set-IHSubnetRange {
    [CmdLetBinding()]
    param(
        $vnet,
        [string]$newAddressSpace
    )
    $Newbit = ($newAddressSpace).Split(".")

    foreach ($Subnet in (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet)) { 
        if($Subnet.Name -ne "Temp-Subnet") {       
            $bit = ($Subnet.AddressPrefix).Split(".")   
            $NewSubnet = ($bit[0] = $Newbit[0]) + "." + ($bit[1] = $Newbit[1])  + "." + $bit[2]  + "." + $bit[3]
            Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Subnet.Name -AddressPrefix $NewSubnet
        }
    }
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
} # Is working
function Reset-IHVpnConnection {
    [CmdLetBinding()]
    param(
        $vnet,
        [Parameter(Mandatory)]
        [string]$gatewayIpName,
        [Parameter(Mandatory)]
        [string]$VirtualNetworkGatewayName,
        [Parameter(Mandatory)]
        [string]$LocalGatewayName,
        [Parameter(Mandatory)]
        [string]$ConnectionName,
        [Parameter(Mandatory)]
        [string]$rgName,
        [Parameter(Mandatory)]
        [string]$region,
        $SharedKey
    )
    foreach ($Subnet in (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet)) {
        if($Subnet.Name -eq "GatewaySubnet") {             
                $GatewaySubnetId = $Subnet.Id     
        }          
    }
    $gwpip= New-AzureRmPublicIpAddress -Name $gatewayIpName -ResourceGroupName $rgName -Location $region -AllocationMethod Dynamic
    $gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name "gwipconfig" -SubnetId $GatewaySubnetId -PublicIpAddressId $gwpip.Id

    $params = @{
        Name = $VirtualNetworkGatewayName
        ResourceGroupName = $rgName
        Location = $region
        IpConfigurations = $gwipconfig
        GatewayType = 'Vpn'
        VpnType = 'RouteBased'
        GatewaySku = 'Standard'
    }
    #splat params against command
    New-AzureRmVirtualNetworkGateway @params

    $gateway1 = Get-AzureRmVirtualNetworkGateway -Name $VirtualNetworkGatewayName -ResourceGroupName $rgName
    $local = Get-AzureRmLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $rgName
    New-AzureRmVirtualNetworkGatewayConnection -Name $ConnectionName -ResourceGroupName $rgName `
    -Location $region -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local `
    -ConnectionType IPsec -RoutingWeight 10 -SharedKey $SharedKey
}# Is working
function Set-IHVMInCorrectSubnet {
    [CmdLetBinding()]
    param (
        $vnet
    )
    # Move all VM's to Temp Subnet
    $TempSubnetId = (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name Temp-Subnet).Id
    $AllNics = Get-AzureRmNetworkInterface

    foreach ($Nic in $AllNics) {    
        if($Nic.IpConfigurations.Subnet.Id -eq $TempSubnetId){
            $Nic.IpConfigurations.Subnet.Id = (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet | Out-GridView -PassThru).Id 
            Set-AzureRmNetworkInterface -NetworkInterface $Nic -Verbose        
        }             
    }
}# Is working
function Clear-IHNetwork {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$rgName,
        [Parameter(Mandatory)]
        [string]$vnetName
    )
    $params = @{
        Name = 'Temp-Subnet'
        VirtualNetwork = (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName)
    }
    Remove-AzureRmVirtualNetworkSubnetConfig @params | Set-AzureRmVirtualNetwork

    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName
    $NewPrefix = (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName).AddressSpace.AddressPrefixes[1]
    $vnet.AddressSpace.AddressPrefixes = $NewPrefix
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
}

Set-IHVirtualNetwork -rgName $rgName -vnetName $vnetName -VirtualNetworkGatewayName $VirtualNetworkGatewayName -newAddressSpace $newAddressSpace
Set-IHSubnetRange -vnet (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName) -newAddressSpace $newAddressSpace

# Moving nics
Set-IHVMInCorrectSubnet -vnet (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName)

# REcreate Connection VPN
$params = @{
    vnet = (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName)
    gatewayIpName = $gatewayIpName
    VirtualNetworkGatewayName = $VirtualNetworkGatewayName
    LocalGatewayName = $LocalGatewayName
    ConnectionName = $ConnectionName
    rgName = $rgName
    region = $region
    SharedKey = $SharedKey
}
Reset-IHVpnConnection @params

# Clean up network
Clear-IHNetwork -rgName $rgName -vnetName $vnetName