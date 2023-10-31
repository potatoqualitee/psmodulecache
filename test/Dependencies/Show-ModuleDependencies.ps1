#Windows Powershell v5.1
#Build the dependencies of the modules installed by Install-Module (cf. $env:PsModulePath)
#Assumes a directory name construct of the type :
#  $ModulePath\ModuleName\VersionNumber
#
#Exemple: .\Show-ModuleDependencies.ps1 'C:\Program Files\WindowsPowerShell\Modules'
#Exemple: .\Show-ModuleDependencies.ps1 .\psmodulecache\test\Dependencies\Gallery

param(
   [Parameter(Mandatory)]
   [ValidateNotNullOrEmpty()]
   $ModulePath
)

#region PowershellGet versionning


function Get-PowerShellGetVersion {
   # Separates Version from Prerelease string (if needed) and validates each.
   #Adapted from :
   # https://github.com/PowerShell/PowerShellGetv2/blob/master/src/PowerShellGet/private/functions/ValidateAndGet-VersionPrereleaseStrings.ps1
   #
   #Note :
   #The original code reconstructs the version number (see FullVersion),
   # the returned version number may no longer correspond to the one passed as a parameter.
   #
   #See to :
   # https://learn.microsoft.com/en-us/powershell/scripting/gallery/concepts/module-prerelease-support?view=powershell-5.1
   Param
   (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Version
   )

   #In the original code this parameter is used by Update-ModuleManifest
   #It is not used here, but the code references it using implicit conversions
   [string] $Prerelease = [string]::Empty

   # Scripts scenario
   if ($Version -match '-' -and -not $Prerelease) {
      $Version, $Prerelease = $Version -split '-', 2
   }

   # Remove leading hyphen (if present) and trim whitespace
   if ($Prerelease -and $Prerelease.StartsWith('-') ) {
      $Prerelease = $Prerelease -split '-', 2 | Select-Object -Skip 1
   }
   if ($Prerelease) {
      $Prerelease = $Prerelease.Trim()
   }

   # only these characters are allowed in a prerelease string
   $validCharacters = "^[a-zA-Z0-9]+$"
   $prereleaseStringValid = $Prerelease -match $validCharacters
   if ($Prerelease -and -not $prereleaseStringValid) {
      #Error for the Github Action runner
      $message = $PSModuleCacheResources.InvalidCharactersInPrereleaseString -f $Prerelease
      #Error for the caller
      throw "Get-PowerShellGetVersion : $Message"
   }

   # Validate that Version contains exactly 3 parts
   if ($Prerelease -and -not ($Version.ToString().Split('.').Count -eq 3)) {
      $message = $PSModuleCacheResources.IncorrectVersionPartsCountForPrereleaseStringUsage -f $Version
      throw "Get-PowerShellGetVersion : $Message"
   }

   # try parsing version string
   [Version]$VersionVersion = $null
   if (-not ( [System.Version]::TryParse($Version, [ref]$VersionVersion) )) {
      $message = $PSModuleCacheResources.InvalidVersion -f ($Version)
      throw "Get-PowerShellGetVersion : $Message"
   }

   $fullVersion = if ($Prerelease) { "$VersionVersion-$Prerelease" } else { "$VersionVersion" }

   $results = @{
      Version     = "$VersionVersion"
      Prerelease  = $Prerelease
      FullVersion = $fullVersion
   }
   return $results
}

function Test-Version {
   #Return $true for a valid PowerShellGet version (with or without prerelease).
   param(
      [string] $Version
   )
   try {
      Get-PowerShellGetVersion -Version $Version > $null
      return $true
   } catch {
      return $false
   }
}

function Test-PrereleaseVersion {
   #Return $true for a PowerShellGet version with a prerelease.
   param( [string]$Version )
   try {
      $PowerShellGetVersion = Get-PowerShellGetVersion -Version $Version
      return $PowerShellGetVersion.Prerelease -ne ([string]::Empty)
   } catch {
      #$Version has invalid syntax
      return $false
   }
}

function ConvertTo-Version {
   #return a PowerShellGet version number without the prerelease
   #Save-Module uses a [Version] as directory name for a prerelease module.
   param(
      [string]$Version
   )
   #Note : Here one should only receive valid and authorized version numbers.

   $PowerShellGetVersion = Get-PowerShellGetVersion -Version $Version

   #For '01.1.1' return '1.1.1'
   #For '1.2.3--' return '1.2.3'
   #for '1.2.3.4--' return '1.2.3.4'
   return $PowerShellGetVersion.Version
}
#endregion

#region Read and analyze manifest content
Function Get-ModuleVersion {
   param( $RequiredModules )

   if ($RequiredModules.ContainsKey('ModuleVersion')) {
      Return $RequiredModules.ModuleVersion
   } else {
      #RequiredVersion was added in Windows PowerShell 5.0.
      Return $RequiredModules.RequiredVersion
   }
   #todo Key : 'MaximumVersion' was added in Windows PowerShell 5.1.
   #todo You can define an acceptable version range for the module by specifying the ModuleVersion and MaximumVersion keys together.
}

Function Get-ModuleName {
   param(
      $RequiredModules,

      [ValidateNotNullOrEmpty()]
      [string] $Default
   )
   if ($RequiredModules.ContainsKey('RootModule')) {
      $Name = $RequiredModules.RootModule
   } else {
      $Name = $RequiredModules.ModuleToProcess
   }

   #Previous keys are not required in a manifest ( PS v2 )
   if ([string]::IsNullOrEmpty($Name))
   { $Name = $Default }

   Return  [System.IO.Path]::GetFileNameWithoutExtension($Name)
}

function New-ModuleWithoutDetails {
   param($ModuleName)

   New-Object -TypeName PSObject -Property @{
      ModuleVersion   = $null
      RequiredVersion = $null
      ModuleName      = $ModuleName
      GUID            = $null
      Label           = "${ModuleName}-"
   }
}

Function New-Dependency {
   #Build the list of required modules
   #See the rules of 'RequiredModule' key :
   # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_module_manifests?view=powershell-5.1#requiredmodules
   param( $RequiredModules )

   Foreach ( $CurrentModule in $RequiredModules) {
      if ($CurrentModule -is [string]) {
         $PSObject = New-ModuleWithoutDetails $CurrentModule
      } else {
         $Name = $CurrentModule.ModuleName
         $Version = Get-ModuleVersion $CurrentModule
         $PSObject = New-Object -TypeName PSObject -Property @{
            ModuleVersion   = $CurrentModule.ModuleVersion
            RequiredVersion = $CurrentModule.RequiredVersion
            ModuleName      = $Name
            GUID            = $CurrentModule.GUID
            Label           = ('{0}-{1}' -F $Name, $Version) #Module dependency can not use a prerelease version.
         }
      }
      Write-Output $PSObject
   }
}

Function Get-ModuleDependencies {
   param( $ManifestPath)

   if (Test-Path $ManifestPath) {
      Write-Verbose "`tRead Primary manifest '$ManifestPath'"
      #We read a manifest and its dependencies.
      #Here we do not read the dependencies of the dependencies.
      try {
         $Datas = Import-PowerShellDataFile -Path $ManifestPath
         $RootModuleName = Get-ModuleName -RequiredModules $Datas -Default $ModuleName
         #Current node name displayed in the graph
         $Label = '{0}-{1}' -F $RootModuleName, $Datas.ModuleVersion
         $Dependencies = @()
         if ($Datas.ContainsKey('RequiredModules')) {
            $Dependencies = New-Dependency -RequiredModules $Datas.RequiredModules
         } else {
            Write-Verbose "No Dependency for '$Label'"
         }
         $MainModule = New-Object -TypeName PSObject -Property @{
            ModuleVersion   = $Datas.ModuleVersion
            RequiredVersion = $null
            ModuleName      = $RootModuleName
            GUID            = $Datas.GUID
            Dependencies    = $Dependencies
            Label           = $Label
         }
         Write-Output $MainModule

      } catch [System.InvalidOperationException] {
         <#
        Note :
        Import-PowerShellDataFile can trigger 'System.InvalidOperationException' for some manifests.
        Example https://github.com/PoshCode/Pansies

        In this case, and after checking the content of the manifest, it is still possible to retrieve the information with:
        $Code=get-content 'C:\Temp\Pansies.psd1' -Raw ; $Datas=Invoke-Expression $Code
        #>
         Write-Error "The content of the manifest '$ManifestPath' is not considered safe by the cmdlet 'Import-PowerShellDataFile'."
      } catch {
         throw $_
      }

   } else {
      Write-Verbose "Search a main module : Path not exist '$ManifestPath'"
      #We add a module name, without knowing its dependencies
      $ModuleName = [System.IO.Path]::ChangeExtension($ManifestPath, '.psm1')
      if (Test-Path $ModuleName) {
         $PSObject = New-ModuleWithoutDetails ([System.IO.Path]::GetFileNameWithoutExtension($ModuleName)) |
         Add-Member -MemberType 'NoteProperty' -Name 'Dependencies' -Value $null -PassThru
         Write-Output $PSObject
      }
   }
}
#endregion

function Get-DirectoryVersionModule {
   param($Path)
   #Read installed modules
   # the directory name composition is of the type :  $ModulePath\ModuleName\VersionNumber\ModuleName.psd1
   Foreach ($Primary in Get-ChildItem -Path $Path -Directory) {
      $ModuleName = $Primary.Name
      Write-Verbose "Read Module  '$Path' ($Modulename)"
      Foreach ($ModuleVersion in Get-ChildItem -Path "$Path\$ModuleName" -Directory | Where-Object { Test-Version $_.Name }) {
         Write-Verbose "`tRead module version path '$Path\$ModuleName'"
         $ModuleVersion = $ModuleVersion.Name

         $ManifestPath = "$Path\$ModuleName\$ModuleVersion\$ModuleName.psd1"
         Get-ModuleDependencies -ManifestPath $ManifestPath
      }
   }
}

<#
#Read modules into a project directory
# the directory name composition is of the type :  $ModulePath\ModuleName\ModuleName.psd1
$Result = Foreach ($Primary in Get-ChildItem -Path $ModulePath -Directory) {
    $ModuleName = $Primary.Name
    Write-Verbose "Read Module  '$ModulePath' ($modulename)"
    $ManifestPath = "$ModulePath\$ModuleName\$ModuleName.psd1"
    Get-ModuleDependencies -ManifestPath $ManifestPath
}

#Read only one module into a project directory
# the directory name composition is of the type :  $ModulePath\ModuleName\ModuleName.psd1
 $ManifestPath = "C:\Program Files\WindowsPowerShell\Modules\PSDevOps\0.5.8"
 Get-ModuleDependencies -ManifestPath $ManifestPath
#>

if (Test-Path $ModulePath) {
   $Result = Get-DirectoryVersionModule -Path $ModulePath
} else {
   throw "The path not exist : '$ModulePath'"
}


Import-Module PSAutograph
#https://github.com/LaurentDardenne/PSAutograph

try {
   $viewer = New-MSaglViewer
   $ObjectMap = @{
      "System.Management.Automation.PSCustomObject" = @{
         Follow_Property = "Dependencies"
         Follow_Label    = "Dependency"
         Label_Property  = "Label"
      }
   }

   $graph = New-MSaglGraph

   #Change the layout method to 'IncrementalLayout'
   $Graph.LayoutAlgorithmSettings = [Microsoft.Msagl.Layout.Incremental.FastIncrementalLayoutSettings]::new()

   Set-MSaglGraphObject -Graph $graph -InputObject ($Result) -objectMap $ObjectMap

   Show-MSaglGraph $viewer $graph > $null
} finally {
   if ($null -ne $Viewer)
   { $Viewer.Dispose() }
}

