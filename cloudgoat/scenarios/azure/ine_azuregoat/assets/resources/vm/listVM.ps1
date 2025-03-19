workflow Get-AzureVM
{
    Disable-AzContextAutosave -Scope Process
    $AzureContext = (Connect-AzAccount -Identity -AccountId 2bf54b19-13d0-448b-adbc-2f03060d2eb5).context
	$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext


    $VMs = Get-AzVM -ResourceGroupName azuregoat_app

    
	Write-Output "Finding VM"
    
	Write-Output $VMs[0]
    
}