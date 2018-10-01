Function Test-Json
{
  Param(
    [string]
    $FilePath
  )

  Context "JSON Structure" {
    It "Converts from JSON and has the expected properties" {
      $expectedProperties = '$schema',
                            'contentVersion',
                            'parameters',
                            'variables',
                            'resources',
                            'outputs' | Sort-Object

      $templateProperties = (get-content "$FilePath" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | ForEach-Object -Process {$_.Name} | Sort-Object
      $templateProperties | Should -Be $expectedProperties
    }
  }

  $jsonMainTemplate = Get-Content "$FilePath"
  $objMainTemplate = $jsonMainTemplate | ConvertFrom-Json -ErrorAction SilentlyContinue

  $parametersUsage = [System.Text.RegularExpressions.RegEx]::Matches($jsonMainTemplate, "parameters(\(\'\w*\'\))") | Select-Object -ExpandProperty Value -Unique
  Context "Parameters Usage $parameterUsage" {
    ForEach($parameterUsage In $parametersUsage)
    {
      $parameterUsage = $parameterUsage.SubString($parameterUsage.IndexOf("'") + 1).Replace("')","")
    
      It "should have a parameter called $parameterUsage" {
        $objMainTemplate.parameters.$parameterUsage | Should -Not -Be $null
      }
    }
  }

  $variablesUsage = [System.Text.RegularExpressions.RegEx]::Matches($jsonMainTemplate, "variables(\(\'\w*\'\))") | Select-Object -ExpandProperty Value -Unique
  Context "Variables Usage" {
    ForEach($variableUsage In $variablesUsage)
    {
      $variableUsage = $variableUsage.SubString($variableUsage.IndexOf("'") + 1).Replace("')","")
      
      It "should have a variable called $variableUsage" {
        $objMainTemplate.variables.$variableUsage | Should -Not -Be $null
      }
    }
  }
  Context "Variables Debug" {
    $debug = $objMainTemplate.variables.debug
    If($debug){
        $debugproperties = $debug | Get-Member | Where-Object membertype -eq Noteproperty | Select-Object -ExpandProperty name
        foreach ($property in $debugproperties){
            It    "Debug Property $property Should be True"{
               $debug.$property | Should -be $true
            }
        }
    }
  }
  $nestedTemplates = $objMainTemplate.resources | Where-Object -Property Type -IEQ -Value "Microsoft.Resources/deployments"
  
  if($nestedTemplates -ne $null)
  {
    ForEach($nestedTemplate In $nestedTemplates)
    {
      If($nestedTemplate.properties.templateLink.uri -ne $null)
      {
        $nestedTemplateFileName = [System.Text.RegularExpressions.RegEx]::Matches($nestedTemplate.properties.templateLink.uri, "\'\w*\.json\??\'").Value
        $nestedTemplateFileName = $nestedTemplateFileName.SubString($nestedTemplateFileName.IndexOf("'") + 1).Replace("'","").Replace('?','')

        Context "Nested Template: $nestedTemplateFileName" {
          It "should exist the nested template at $WorkingFolder\nested\$nestedTemplateFileName" {
            "$WorkingFolder\nested\$nestedTemplateFileName" | Should -Exist
          }

          if(Test-Path "$WorkingFolder\nested\$nestedTemplateFileName")
          {
            $nestedParameters = (Get-Content "$WorkingFolder\nested\$nestedTemplateFileName" | ConvertFrom-Json).parameters
            $requiredNestedParameters = $nestedParameters | Get-Member -MemberType NoteProperty | Where-Object -FilterScript {$nestedParameters.$($_.Name).defaultValue -eq $null} | ForEach-Object -Process {$_.Name}

            
            ForEach($requiredNestedParameter In $requiredNestedParameters)
            {
              It "should set a value for $requiredNestedParameter" {
                $nestedTemplate.properties.parameters.$requiredNestedParameter | Should -Not -BeNullOrEmpty
              }
            }
          }
        }
      }
    }
  }

  $scriptFolders = [System.Text.RegularExpressions.RegEx]::Matches($jsonMainTemplate, "\w+\.(gz|tar|tar\.gz|zip)")
  ForEach($scriptFolder In $scriptFolders)
  {
    $CompressedFileName = ($scriptFolder.Value).Replace(".tar.gz","").Replace(".tar","").Replace(".gz","").Replace(".zip","")

    Context "Script Folder: $CompressedFileName" {
      It "should exists in the scripting folder" {
        "$WorkingFolder\scripts\$CompressedFileName" | Should -Exist
      }

      It "shouldn't be empty" {
        (Get-ChildItem -Path "$WorkingFolder\scripts\$CompressedFileName" -Recurse).Length | Should -BeGreaterThan 0
      }
    }
  }

  $scriptFiles = [System.Text.RegularExpressions.RegEx]::Matches($jsonMainTemplate, "\w+\.(ps1|sh|py)")
  ForEach($scriptFile In $scriptFiles)
  {
    Context ("Script File: {0}" -f $scriptFile.Value) {
      $scriptType = $scriptFile.Value.SubString($scriptFile.Value.LastIndexOf('.'))
      $script = Get-ChildItem -Path "$WorkingFolder\scripts" -Filter $scriptFile.Value -Recurse | Select-Object -First 1

      It "should exist in the scripts folder" {
        $script | Should -Not -BeNullOrEmpty
      }

      if($script)
      {
        if($scriptType -ieq ".ps1")
        {
          # It "is a valid Powershell Code"{
          #     $psFile = Get-Content -Path $script.FullName -ErrorAction Stop
          #     $errors = $null
          #     $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
          #     $errors.Count | Should -Be 0
          # }

          $ReferencedModules = Get-Content $script.FullName | Where-Object -FilterScript {$_ -ilike '*Import-DSCResource*'} | ForEach-Object -Process {$_.SubString($_.LastIndexOf(' ') + 1).Replace("'","")}

          ForEach($Module In $ReferencedModules)
          {
            $ModulePath = Join-Path -Path $script.DirectoryName -ChildPath $Module
            $ModuleSharedPath = Join-Path -Path "$WorkingFolder\scripts\Modules" -ChildPath $Module

            It "has a Module folder for: $Module"{
              $result = (Test-Path $ModulePath) -or (Test-Path $ModuleSharedPath)
              
              $result | Should -Be $true
            }

            It "has content in $Module folder"{
              If(Test-Path $ModulePath) {
                $result = Get-ChildItem -Path $ModulePath -Recurse | Measure-Object -Sum -Property Length | Select-Object -ExpandProperty Sum  
              }
              else {
                $result = Get-ChildItem -Path $ModuleSharedPath -Recurse | Measure-Object -Sum -Property Length | Select-Object -ExpandProperty Sum  
              }
              
              $result | Should BeGreaterThan 0
            }

            It "has the definition file ($Module.psd1)" {
              if(Test-Path $ModulePath) {
                $result = Get-ChildItem -Path $ModulePath -Filter "$Module.psd1" -Recurse
              }
              else {
                $result = Get-ChildItem -Path $ModuleSharedPath -Filter "$Module.psd1" -Recurse
              }
              
              $result | Should -Not -BeNullOrEmpty
            }
          }
        }
        elseif($scriptType -ieq ".sh")
        {

        }
        elseif($scriptType -ieq ".py")
        {

        }
      }
    }
  }
}

$WorkingFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

If(!(Get-Module -Name "powershell-yaml" -ListAvailable))
{
  Write-Host "Installing Powershell-YAML Module"
  Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}


Describe "Solution Standard" {
  Context "Folder & File Structure" {
    ForEach($Folder In @('docs','nested','scripts'))
    {
      It "should have a '$Folder' folder" {
        "$WorkingFolder\$Folder" | Should -Exist
      }
    }

    It "should have a build.ps1 file" {
      "$WorkingFolder\build.ps1" | Should -Exist
    }
  }

  Context "Documentation" {
    It "should have a README.MD file" {
      "$WorkingFolder\README.MD" | Should -Exist
    }

    It "should have an Introduction section" {
      "$WorkingFolder\README.MD" | Should -FileContentMatch "# Introduction "
    }

    It "should document the project" {
      (Get-FileHash -Path "$WorkingFolder\README.MD" -Algorithm SHA256).Hash | Should -Not -Be "CA0DBCC51DF149421A05A71595964BAE965A4FA7755F73A52EE730132505BF4E"
      "$WorkingFolder\README.MD" | Should -Not -FileContentMatch "TODO: Give a short introduction of your project."
      "$WorkingFolder\README.MD" | Should -Not -FileContentMatch "TODO: Guide users through getting your code up and running on their own system."
      "$WorkingFolder\README.MD" | Should -Not -FileContentMatch "TODO: Describe and show how to build your code and run the tests."
      "$WorkingFolder\README.MD" | Should -Not -FileContentMatch "TODO: Explain how other users and developers can contribute to make your code better."
    }
  }

  $script:armTemplates = @()

}


if(Test-Path "$WorkingFolder\software.json")
{
  Describe "Software"{
    Context "File Syntax" {
      It "Converts from JSON and has the expected properties" {
        $expectedProperties = 'Hash',
                              'HashType',
                              'Name',
                              'Platform',
                              'Uri' | Sort-Object
  
        $templateProperties = (get-content "$WorkingFolder\software.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | ForEach-Object -Process {$_.Name} | Sort-Object
        $templateProperties | Should -Be $expectedProperties
      }
    }

    $SoftwareList = Get-Content "$WorkingFolder\software.json" -Raw | ConvertFrom-Json

    ForEach($Software In $SoftwareList)
    {
      $DestinationFolder = "$WorkingFolder\software\{0}" -f $Software.Platform
      $FileName = $Software.Uri.SubString($Software.Uri.LastIndexOf('/')+1)

      Context ("Software: {0}" -f $Software.Name){
        It "should have a Name property" {
          $Software.Name | Should -Not -BeNullOrEmpty
        }

        It "should have a Hash property" {
          $Software.Hash | Should -Not -BeNullOrEmpty
        }

        It "should have a HashType property" {
          $Software.HashType | Should -Not -BeNullOrEmpty
        }

        It "should have a Platform property" {
          $Software.Platform | Should -Not -BeNullOrEmpty
        }

        It "should have a Uri property" {
          $Software.Uri | Should -Not -BeNullOrEmpty
        }

        It ("should exists at software\{0}\{1}" -f $Software.Platform, $FileName) {
          "$DestinationFolder\$FileName" | Should -Exist
        }

        It "should match the hash value" {
          (Get-FileHash -Path "$DestinationFolder\$FileName" -Algorithm $Software.HashType).Hash | Should -Be $Software.Hash
        }
      }
    }
  }
}