Login-AzureRmAccount;
Get-AzureRMSubscription | Out-GridView -PassThru | Select-AzureRmSubscription;
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.ClassicInfrastructureMigrate;
Get-AzureRmResourceProvider -ProviderNamespace Microsoft.ClassicInfrastructureMigrate;
Add-AzureAccount;
Get-AzureSubscription | Out-GridView -PassThru | Select-AzureSubscription;

# IaaS migration 
# VMS in clousd service migrartion
$serviceName = (Get-AzureService | Out-GridView -PassThru).ServiceName
$deployment = Get-AzureDeployment -ServiceName $serviceName
$deploymentName = $deployment.DeploymentName
#Move-AzureService -Prepare -ServiceName $serviceName -DeploymentName $deploymentName -CreateNewVirtualNetwork  NEW NETWORK

# OPVRAGEN NETWERK EN SUBNET
$existingVnetRGName = "Ivo_Haagen"
$vnetName = "MigrationTesting"
$subnetName = "default"
Move-AzureService -Prepare -ServiceName $serviceName -DeploymentName $deploymentName -UseExistingVirtualNetwork -VirtualNetworkResourceGroupName $existingVnetRGName -VirtualNetworkName $vnetName -SubnetName $subnetName # EXISTING NETWORK
$vmName = (Get-AzureVM -ServiceName $serviceName | Out-GridView -PassThru).Name
$vm = Get-AzureVM -ServiceName $serviceName -Name $vmName
$migrationState = $vm.VM.MigrationState
#Move-AzureService -Abort -ServiceName $serviceName -DeploymentName $deploymentName ABBORT
Move-AzureService -Commit -ServiceName $serviceName -DeploymentName $deploymentName


# VMs and VNET
$vnetName = "MigrationTest"
Move-AzureVirtualNetwork -Prepare -VirtualNetworkName $vnetName
#Move-AzureVirtualNetwork -Abort -VirtualNetworkName $vnetName     ABBORT
Move-AzureVirtualNetwork -Commit -VirtualNetworkName $vnetName


# Storage migration
$storageAccountName = (Get-AzureStorageAccount | Out-GridView -PassThru).Label
Move-AzureStorageAccount -Prepare -StorageAccountName $storageAccountName
#Move-AzureStorageAccount -Abort -StorageAccountName $storageAccountName       ABBORT
Move-AzureStorageAccount -Commit -StorageAccountName $storageAccountName