$mycreds 
Login-AzureRmAccount -Credential $mycreds -ServicePrincipal -TenantId "88fbe04f-1355-42ce-a58e-7bbc0472a1b0" -Subscription "35f47e74-8c1f-4fcb-85d1-d336eba62ab1" 


$AppId = "dcad29e1-7d07-403d-b401-874b931cb3e3"
$PWord = ConvertTo-SecureString "wUhbM1HRCorNzgSE7JAtmZ7DBm6DoIjCZ+GuVZ+bMrM=" -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $AppId, $PWord

$TenantId = "88fbe04f-1355-42ce-a58e-7bbc0472a1b0"
Add-AzureAnalysisServicesAccount -Credential $Credential -ServicePrincipal -TenantId $TenantId -RolloutEnvironment "westcentralus.asazure.windows.net"

Login-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantId

