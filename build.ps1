$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$artifactFolder = "$here\output\Artifacts"
$softwareFolder = "$here\output\Software"
$scratchFolder = "$here\scratch"


"Cleaning Up Output folder"
if(Test-Path "$here\output"){Get-ChildItem "$here\output" -Recurse | Remove-Item -Force -Recurse}

if(!(Test-Path $artifactFolder)){
  New-Item -Path $artifactFolder -ItemType Directory | Out-Null
}


if(!(Test-Path $softwareFolder))
{
  New-Item -Path $softwareFolder -ItemType Directory | Out-Null
}

ForEach($File In $releaseFiles)
{
  "Copying $File"
  Copy-Item -Path "$here\$File" -Destination "$here\output"
}

"Copying azuredeploy.json"
Copy-Item -Path "$here\azuredeploy.json" -Destination "$artifactFolder"

if(Test-Path "$here\nested"){
  "Copying nested JSON files"
  Copy-Item -Path "$here\nested\*.json" -Destination "$artifactFolder" -Recurse
}


if(Test-Path "$here\software\Windows"){
  "Copying software files for Windows platform"
  Copy-Item -Path "$here\software\Windows" -Filter "*.*" -Destination "$softwareFolder" -Recurse
}

if(Test-Path "$here\software\Linux"){
  "Copying software files for Linux platform"
  Copy-Item -Path "$here\software\Linux" -Filter "*.*" -Destination "$softwareFolder" -Recurse
}

if(Test-Path "$here\scripts"){
  if(Test-Path $scratchFolder)
  {
    Remove-Item $scratchFolder -Recurse -Force
  }

  "Creating Scratch folder"
  New-Item -Path $scratchFolder -ItemType Directory | Out-Null

  "Preparing scripts"
  Get-childitem "$here\scripts" -Directory | Where-Object {$_.Name -ne 'QA' -and $_.Name -ne 'Modules'} | ForEach-Object {
    $scratchPath = "{0}\{1}" -f $scratchFolder, $_.Name

    "[{0}] Copying to scratch folder" -f $_.Name
    Copy-Item -Path $_.FullName -Destination $scratchPath -Recurse | Out-Null

    $ReferencedModules = Get-ChildItem -Path $_.FullName -Filter *.ps1 | Select-Object -First 1 | Get-Content  | Where-Object -FilterScript {$_ -ilike '*Import-DSCResource*'} | ForEach-Object -Process {$_.SubString($_.LastIndexOf(' ') + 1).Replace("'","")}

    ForEach($ReferencedModule In $ReferencedModules)
    {
      "[{0}] Verifying Module: {1}" -f $_.Name, $ReferencedModule

      if(!(Test-Path ("{0}\{1}" -f $scratchPath, $ReferencedModule))) {
        if(Test-Path "$here\scripts\Modules\$ReferencedModule") {
          "[{0}] Copying Module {1} from shared location" -f $_.Name, $ReferencedModule
          Copy-Item -Path "$here\scripts\Modules\$ReferencedModule" -Destination "$scratchPath\$ReferencedModule" -Recurse
        }
        else {
          throw ("Missing Modules {0} for {1}" -f $ReferencedModule, $_.Name)
        }
      }
    }

    "[{0}] Compressing...." -f $_.Name
    Compress-Archive "$scratchPath\*" -DestinationPath ("$artifactFolder\{0}.zip" -f $_.Name)
  }

  Remove-Item -Path $scratchFolder -Recurse -Force

  Get-ChildItem "$here\scripts" -File | Copy-Item -Destination "$artifactFolder"
}

"Done!"