param(
  $StorageSASToken = "?sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2020-06-30T22:56:18Z&st=2018-06-05T14:56:18Z&spr=https&sig=ggxCMf64yrAFhB5AztDiSLRlzCltEKDiXgdFF8Z7NBM%3D"
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

If(!(Test-Path "$here\software.json"))
{
  Exit(0)
}

if(!(Test-Path "$here\software"))
{
  New-Item -Path "$here\software" -ItemType Directory | Out-Null
}

$SoftwareList = Get-Content "$here\software.json" -Raw | ConvertFrom-Json
$webClient = New-Object System.Net.WebClient

ForEach($Software In $SoftwareList)
{
  $DestinationFolder = "$here\software\{0}" -f $Software.Platform
  $FileName = $Software.Uri.SubString($Software.Uri.LastIndexOf('/')+1)
  $CurrentHash = $null

  if(!(Test-Path $DestinationFolder))
  {
    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
  }

  Write-Host ("Working on {0}" -f $Software.Name)
  Write-Host ("Verifying if it's already downloaded")
  if(Test-Path "$DestinationFolder\$FileName")
  {
    $CurrentHash = Get-FileHash -Path "$DestinationFolder\$FileName" -Algorithm $Software.HashType
  }
  
  If($CurrentHash.Hash -ne $Software.Hash)
  {
    Write-Host "Downloading File..."
    $webClient.DownloadFile($($Software.Uri + $StorageSASToken), "$DestinationFolder\$FileName")
    Write-Host "Complete!"
  }
  else
  {
    Write-Host "File is already downloaded"
  }
}