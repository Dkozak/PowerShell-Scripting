$Gateway = Get-AzureRmVirtualNetworkGateway -ResourceGroupName AzureTest -Name "AzureSiteVPNtoHK"
Resize-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $Gateway -GatewaySku "Standard"
