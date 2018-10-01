# MyPath is the path where you saved DeployTemplate.ps1
# MyResourceGroup is the name of the Azure ResourceGroup that contains your Azure Automation account
# MyAutomationAccount is the name of your Automation account

param(
  [string]$Path
)
$AppId = "dcad29e1-7d07-403d-b401-874b931cb3e3"
$PWord = ConvertTo-SecureString "wUhbM1HRCorNzgSE7JAtmZ7DBm6DoIjCZ+GuVZ+bMrM=" -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $AppId, $PWord

$TenantId = "88fbe04f-1355-42ce-a58e-7bbc0472a1b0"
Login-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantId

$importParams = @{
    Path = '_ARM-Runbook-CI\AzureARMtemplates_Source\Artifacts\Runbook.ps1'
    ResourceGroupName = 'ARM-Runbook'
    AutomationAccountName = 'ARM-Deployment'
    Type = 'PowerShell'
}
Import-AzureRmAutomationRunbook @importParams -Force

# Publish the  ARM runbook
$publishParams = @{
    ResourceGroupName = 'ARM-Runbook'
    AutomationAccountName = 'ARM-Deployment'
    Name = 'Runbook'
}
# Publish the RB to Azure
Publish-AzureRmAutomationRunbook @publishParams