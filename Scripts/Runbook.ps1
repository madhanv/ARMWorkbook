param(
  [Parameter (Mandatory= $true)]
  [String] $ResourceGroupName
)
$connectionName = "AzureRunAsConnection"


# Get the connection "AzureRunAsConnection "
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName  

$tenantID = $servicePrincipalConnection.TenantId
$applicationId = $servicePrincipalConnection.ApplicationId
$certificateThumbprint = $servicePrincipalConnection.CertificateThumbprint

"Logging in to Azure..."
Login-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $tenantID `
    -ApplicationId $applicationId `
    -CertificateThumbprint $certificateThumbprint
"Login Successful"

#Set the parameter values for the Resource Manager template
"Getting all the required parameter to execute ARM template"
$SecurePass = ConvertTo-SecureString "Passw0rd@123456789" -AsPlainText -Force
$Parameters = @{
    Engagement = "MyProject"
    vNetName = "MyVnet"
    virtualNetworkAddressRange = "10.0.0.0/16"
    SubNetworkName = "MyFirstVnet"
    SubNetworkAddressPrefix = "10.0.1.0/24"
    artifactsURI = "https://saforpoc.blob.core.windows.net/files/"
    artifactSasToken = "?sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2019-01-30T23:48:26Z&st=2018-09-25T15:48:26Z&spr=https,http&sig=QVM6%2F1BYO%2FningP%2BlmvHwHUmBRatonqswOzQfuJWwA4%3D"
    adminUsername = "testuser"
    adminPassword = "$SecurePass"
    dnsLabelPrefix = "testvm1234321"
    windowsOSVersion = "2016-Datacenter"
    }


# Deploy the Template
"Deploying Template"

$FileURL = $Parameters.artifactsURI + "azureDeploy.json" + $Parameters.artifactSasToken
New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $FileURL -TemplateParameterObject $Parameters  -Name "Temp2"