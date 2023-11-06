#CaseInsensitive.Tests.ps1
#Checks the case of a module name (retrieve the nuget archive name)

# !!! It is assumed that the modules in this list have no dependencies
$ModuleNames = @(
  #The first case is a case-sensitive module name of the nuget package.
  @{NugetName = 'platyPS'; Modules = 'platyPS'; Shells = 'pwsh'; Updatable = $false }
  @{NugetName = 'platyPS'; Modules = 'PlatyPs'; Shells = 'powershell'; Updatable = $false }
  @{NugetName = 'platyPS'; Modules = 'PlatyPs'; Shells = 'pwsh'; Updatable = $false }
  @{NugetName = 'platyPS'; Modules = 'PlAtYpS:0.14.2'; Shells = 'powershell,pwsh'; Updatable = $false }
  # !!! The indicated module must have a prerelease published on PSGallery
  @{NugetName = 'platyPS'; PrereleaseModules = 'PlaTyPS:2.0.0-preview1'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{NugetName = 'platyPS'; PrereleaseModules = 'platyPS::'; Shells = 'pwsh'; Updatable = $true }
  @{NugetName = 'platyPS'; PrereleaseModules = 'PlatyPs::'; Shells = 'powershell'; Updatable = $true }
  @{NugetName = 'platyPS'; PrereleaseModules = 'platyps::'; Shells = 'pwsh'; Updatable = $true }
  @{NugetName = 'platyPS'; PrereleaseModules = 'PlatyPS::'; Shells = 'powershell,pwsh'; Updatable = $true }


  #The first case is a case-sensitive module name of the nuget package.
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; Modules = 'Microsoft.PowerShell.SecretManagement'; Shells = 'pwsh'; Updatable = $false }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; Modules = 'Microsoft.Powershell.SecretManagement'; Shells = 'powershell'; Updatable = $false }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; Modules = 'microsOFT.Powershell.SecretManagement'; Shells = 'pwsh'; Updatable = $false }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; Modules = 'Microsoft.Powershell.SecretManagement:1.1.2'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; PrereleaseModules = 'Microsoft.Powershell.SecretManagement:1.1.0-preview2'; Shells = 'powershell'; Updatable = $false }

  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; PrereleaseModules = 'Microsoft.PowerShell.SecretManagement::'; Shells = 'pwsh'; Updatable = $true }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; PrereleaseModules = 'Microsoft.Powershell.SecretManagement::'; Shells = 'powershell'; Updatable = $true }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; PrereleaseModules = 'Microsoft.Powershell.SecretManagement::'; Shells = 'pwsh'; Updatable = $true }
  @{NugetName = 'Microsoft.PowerShell.SecretManagement'; PrereleaseModules = 'Microsoft.Powershell.SecretManagement::'; Shells = 'powershell,pwsh'; Updatable = $true }

  @{NugetName = 'string'; Modules = 'PSGallery\String'; Shells = 'pwsh'; Updatable = $false }

  @{NugetName = 'platyPS'; PrereleaseModules = 'PSGallery\platyPS::'; Shells = 'pwsh'; Updatable = $true }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'CaseInsensitive' {

  Context "Validates the case of a module name." {
    It "Retrieve the nuget archive name ('<NugetName>') of the module '<Modules> / '<PrereleaseModules>'." -TestCases $ModuleNames {
      param(
        $NugetName,
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters
      $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
      $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly $NugetName
    }
  }
}


