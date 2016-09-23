workflow Stop-AzureVMs
{   
    param (
        [parameter(Mandatory=$false)] 
        [String]  $AzureADCredentialAssetName = '',
        
        [parameter(Mandatory=$false)] 
        [String] 
        $AzureSubscriptionName = '',

        [parameter(Mandatory=$false)] 
        [String] 
        $ServiceName
    )
    
    # Returns VMs that were started
    [OutputType([PersistentVMRoleContext])]

	$Cred = Get-AutomationPSCredential -Name $AzureADCredentialAssetName
    if ($Cred -eq $null)
    {
        throw "Could not retrieve $AzureADCredentialAssetName credential asset. Check that you created this first in the Automation service."
    }

	# Connect to Azure and select the subscription to work against
	Add-AzureAccount -Credential $Cred -ErrorAction Stop | Write-Verbose

    # Select the subscription if a subscription name is provided 
    if($AzureSubscriptionName -and ($AzureSubscriptionName.Length > 0) -and ($AzureSubscriptionName -ne "default")) {
        Select-AzureSubscription -Name $AzureSubscriptionName | Write-Verbose
    }

	# If there is a specific cloud service, get all VMs that are not stopped in the service 
    # otherwise get all VMs in the subscription
    if ($ServiceName) 
    {
        $VMs = Get-AzureVM -ServiceName $ServiceName | where-object -FilterScript{$_.Status -ne 'StoppedDeallocated'}
    }
    else 
    {
		$VMs = Get-AzureVM
    
    # Stop each of the VMs
    foreach -parallel ($VM in $VMs) 
    {        
        $StopRtn = Stop-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -force -ErrorAction SilentlyContinue 
        $Count = 1 

        if(($StopRtn.OperationStatus) -ne 'Succeeded') 
        { 
            do{ 
                Write-Output "Failed to stop $($VM.Name). Retrying in 60 seconds..." 
                sleep 60 
                $StopRtn = Stop-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -force -ErrorAction SilentlyContinue 
                $Count++ 
            } 
            while(($StopRtn.OperationStatus) -ne 'Succeeded' -and $Count -lt 5) 
        } 
            
        # Check if the VM stopped successfully
        if(($StopRtn.OperationStatus) -ne 'Succeeded')
        {
            Write-Error "$($VM.Name) failed to stop.  VM operation status: ($StopRtn.OperationStatus)."
        }
        else 
        {
            Write-Output $VM
        }
    } 

}
