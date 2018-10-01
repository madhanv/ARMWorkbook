Login-AzureRmAccount
$RG = "Test2"
$MYRG = "ARM-Runbook"

New-AzureRmResourceGroup -Name $MyRG -Location EastUS


$SecurePass = ConvertTo-SecureString "Passw0rd@123456789" -AsPlainText -Force
$ParametersObj = @{
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

$templatePath = "C:\Users\guruprasad.hp\Documents\Guru\EY\POC\ARM-Runbook\azureDeploy.json"

Test-AzureRmResourceGroupDeployment -ResourceGroupName $RG -TemplateFile $templatePath -TemplateParameterObject $ParametersObj
New-AzureRmResourceGroupDeployment -ResourceGroupName $RG -Name Test1 -TemplateFile $templatePath -TemplateParameterObject $ParametersObj

 #"[concat(parameters('artifactsURI'),'WindowsVM.json',parameters('artifactSasToken'))]",
 $TemplateURL = $ParametersObj.artifactsURI + "azureDeploy.json" + $ParametersObj.artifactSasToken
New-AzureRmResourceGroupDeployment  -TemplateUri 