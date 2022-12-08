#GHA.PSmoduleCache.KeyGen.Tests.ps1
#Checks the 'module-to-cache' or/and 'module-to-cache-prerelease' parameters of the Action and the possible syntax errors.

$ModuleToCacheBasic = @(
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'powershell'; Updatable = $False }
  @{Modules = ''; PrereleaseModules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $False }

  @{Modules = 'PSScriptAnalyzer'; Shells = 'powershell'; Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = ''; Shells = 'pwsh'; Updatable = $False }


  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = 'InvokeBuild'; Shells = 'powershell'; Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = 'InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $False }

  @{Modules = 'DbaTools-Library:022.10.25.1,dbatools-core-library:2022.10.25.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'DbaTools-Library:022.10.25.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'DbaTools-Library:22.010.25.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'dbatools-core-library:2022.10.25.1'; Shells = 'powershell,pwsh'; Updatable = $False }

  @{Modules = 'PSScriptAnalyzer:1.20.0,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer:1.20.0,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $False }

  @{Modules = 'PSScriptAnalyzer:1.20.0,PnP.PowerShell::,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PSScriptAnalyzer,PnP.PowerShell::,DTW.PS.FileSystem::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PnP.PowerShell:1.11.22-nightly,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer,PnP.PowerShell:1.11.22-nightly,DTW.PS.FileSystem"; Shells = "powershell,pwsh"; Updatable = $true }
  @{PrereleaseModules = "PnP.PowerShell:1.11.22-nightly"; Shells = "powershell, pwsh"; Updatable = $true }
)

$ModuleToCacheValidVersion = '0.0.0',
'0.0.0.0', #Valid but not tested with Pusblish-Module
'0.0.-0', #Valid but not tested with Pusblish-Module
'0.0.4',
'1.0',
'1.2',
'1.2.3',
'10.20.30',
'1.0.0',
'2.0.0',
'1.1.7',
'01.1.1',
'1.01.1',
'1.1.01',
'2022.1.2.3',
'02.1.2.3',
'2.10.2.03' |
ForEach-Object {
  @{Modules = "Test:$_"; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = "Test:$_"; Shells = 'powershell,pwsh'; Updatable = $true }
}

$ModuleToCacheEmptyModuleName = @(
  @{PrereleaseModules = "PSScriptAnalyzer::,"; Shells = "powershell, pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::,"; Shells = "powershell, pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::,"; PrereleaseModules = "PSScriptAnalyzer::,"; Shells = "powershell, pwsh"; Updatable = $true }

  @{Modules = ",PSScriptAnalyzer::,"; PrereleaseModules = ",PSScriptAnalyzer::"; Shells = "powershell, pwsh"; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer,"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = ",PSScriptAnalyzer"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = ":,PSScriptAnalyzer"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = ":1.0,PSScriptAnalyzer"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = ":PSScriptAnalyzer"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = "::PSScriptAnalyzer"; Shells = "powershell, pwsh"; Updatable = $true }
  @{PrereleaseModules = "::PSScriptAnalyzer"; Shells = "powershell, pwsh"; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer,::,PnP.PowerShell::"; Shells = "'powershell, pwsh'"; Updatable = $true }
)

$ModuleToCacheMissingRequiredVersion = @(
  @{PrereleaseModules = "PSScriptAnalyzer:"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer :"; Shells = "powershell, pwsh"; Updatable = $false }
  @{Modules = "PSScriptAnalyzer:"; Shells = "powershell, pwsh"; Updatable = $false }
  @{Modules = "PSScriptAnalyzer :"; Shells = "powershell, pwsh"; Updatable = $false }
  @{Modules = "PSScriptAnalyzer :"; PrereleaseModules = "PSScriptAnalyzer:"; Shells = "powershell, pwsh"; Updatable = $false }
  @{Modules = "PSScriptAnalyzer:"; PrereleaseModules = "PSScriptAnalyzer :"; Shells = "powershell, pwsh"; Updatable = $false }
)

$ModuleToCacheInvalidVersionNumberSyntax = @(
  @{PrereleaseModules = "PSScriptAnalyzer:."; Shells = "powershell"; Updatable = $false }
  @{Modules = "dbatools-core-library:."; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer:1"; Shells = "pwsh"; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer:1."; Shells = "powershell "; Updatable = $false }
  @{Modules = "PSScriptAnalyzer:1."; Shells = "powershell "; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer:Test"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools-core-library:1.0-alpha"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools-core-library:1.0.0.0-alpha"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools-core-library:1.0.0-alpha.4"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools-core-library:1.0.0-alpha+4"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools-core-library:1.0.0-alpha-4"; Shells = " powershell,pwsh "; Updatable = $false }

  #Semver with constraint
  @{Modules = "dbatools-core-library:=0.2.3"; Shells = " powershell,pwsh "; Updatable = $false }
  @{Modules = "PnP.PowerShell:!=2.0.0+build.1848"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = "dbatools-core-library:=0.2.3"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "PnP.PowerShell:!=2.0.0+build.1848"; Shells = "powershell, pwsh"; Updatable = $false }
)

$ModuleToCacheImmutableCacheCannotContainUpdatableInformation = @(
  @{PrereleaseModules = "PSScriptAnalyzer::"; Shells = "powershell"; Updatable = $false }
  @{Modules = "PSScriptAnalyzer::"; Shells = "powershell"; Updatable = $false }
)

$ModuleToCacheUpdatableCacheMustContainUpdatableInformation = @(
  @{PrereleaseModules = "PSScriptAnalyzer"; Shells = "powershell"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer:1.20.0"; Shells = "powershell"; Updatable = $true }
)

$ModuleToCacheUpdatableModuleCannotContainVersionInformation = @(
  @{PrereleaseModules = "PSScriptAnalyzer::1"; Shells = "powershell"; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer::1."; Shells = "powershell"; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer::1.20"; Shells = "powershell"; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer::1.20.0"; Shells = "powershell"; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer::texte"; Shells = "powershell"; Updatable = $true }
  @{PrereleaseModules = "dbatools-core-library::2022.10.25.1"; Shells = "powershell"; Updatable = $true }


  @{Modules = "PSScriptAnalyzer::1"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::1."; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::1.20"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::1.20.0"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::texte"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "dbatools-core-library::2022.10.25.1"; Shells = "powershell"; Updatable = $true }
)

$ModuleToCacheUnknownModuleName = @(
  #Find-module is only for an updatable cache
  @{Modules = 'NotExist::'; Shells = 'powershell'; Updatable = $true; PrefixIdentifier = $false }
  @{PrereleaseModules = 'NotExist::'; Shells = 'powershell,pwsh'; Updatable = $true; PrefixIdentifier = $true }
)

$global:PSModuleCacheResources = Import-PowerShellDataFile "$PSScriptRoot/../PSModuleCache.Resources.psd1" -ErrorAction Stop
Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

$Repositories = @(
  [PsCustomObject]@{
    name            = 'OttoMatt'
    publishlocation = 'https://www.myget.org/F/ottomatt/api/v2/package'
    sourcelocation  = 'https://www.myget.org/F/ottomatt/api/v2'
  }
)
foreach ($Repository in $Repositories) {
  $Name = $Repository.Name
  try {
    Get-PSRepository $Name -ErrorAction Stop >$null
  } catch {
    if ($_.CategoryInfo.Category -ne 'ObjectNotFound') {
      throw $_
    } else {
      $Parameters = @{
        Name               = $Name
        SourceLocation     = $Repository.SourceLocation
        PublishLocation    = $Repository.PublishLocation
        InstallationPolicy = 'Trusted'
      }
      Write-Output "Register repository '$($Repository.Name)'"
      # An invalid Web Uri is managed by Register-PSRepository
      Register-PSRepository @Parameters
    }
  }
}

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'KeyGen' {

  Context "Syntax for the 'module-to-cache' or 'module-to-cache-prerelease' parameter." {
    It "Syntax for the 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases @($ModuleToCacheBasic; $ModuleToCacheValidVersion) {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      {
        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ModulesCache = Get-ModuleCache $ActionParameters -Pester
        $ModulesCache > $null
      } | Should -Not -Throw
    }
  }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'KeyGen' {

  Context "Invalid syntax for 'module-to-cache' or 'module-to-cache-prerelease' parameter" {
    It "Invalid syntax 'MustDefineAtLeastOneModule'." {
      $Err = { New-ModuleCacheParameter -Modules '' -PrereleaseModules '' -Shells 'Powershell' } | Should -Throw -PassThru
      $Err.Exception.Message | Should -Be $global:PSModuleCacheResources.MustDefineAtLeastOneModule

      $Err = { New-ModuleCacheParameter -Shells 'Powershell' -Updatable } | Should -Throw -PassThru
      $Err.Exception.Message | Should -Be $global:PSModuleCacheResources.MustDefineAtLeastOneModule
    }

    It "Invalid syntax 'ImmutableCacheCannotContainUpdatableInformation' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheImmutableCacheCannotContainUpdatableInformation {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -Match "^An immutable cache cannot contain updatable cache information"
    }

    It "Invalid syntax 'UpdatableCacheMustContainUpdatableInformation' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheUpdatableCacheMustContainUpdatableInformation {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -Match "^An updatable cache must contain cache information"
    }

    It "Invalid syntax 'EmptyModuleName' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheEmptyModuleName {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      if ($ModulesCache.Count -eq 1)
      { $ModulesCache[0] | Should -Match 'A module name is empty for' }
      if ($ModulesCache.Count -eq 2) {
        $ModulesCache[0] | Should -Match 'A module name is empty for'
        $ModulesCache[1] | Should -Match 'A module name is empty for'
      }
      if ($ModulesCache.Count -eq 3) {
        $ModulesCache[0] | Should -Match 'A module name is empty for'
        $ModulesCache[1] | Should -Match 'A module name is empty for'
        $ModulesCache[2] | Should -Match 'A module name is empty for'
      } else { $ModulesCache.Count | Should -Not -BeGreaterThan 4 }
    }

    It "Invalid syntax 'UpdatableModuleCannotContainVersionInformation' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheUpdatableModuleCannotContainVersionInformation {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -Match "^An updatable module must not specify a version number"
    }

    It "Invalid syntax 'MissingRequiredVersion' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheMissingRequiredVersion {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $msg = 'The required version is not specified for'
      if ($ModulesCache.Count -eq 1)
      { $ModulesCache[0] | Should -Match $msg }
      if ($ModulesCache.Count -eq 2) {
        $ModulesCache[0] | Should -Match $msg
        $ModulesCache[1] | Should -Match $msg
      } else { $ModulesCache.Count | Should -Not -BeGreaterThan 3 }
    }

    It "Invalid syntax 'UnknownModuleName' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheUnknownModuleName {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -Match "^Find-Package: No match was found for the specified search criteria"
    }

    It "Invalid syntax 'InvalidVersionNumberSyntax' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheInvalidVersionNumberSyntax {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ModulesCache.Count | Should -Be 2
      $ModulesCache[1] | Should -Match '^The syntax of the version'
      $ModulesCache[0] | Should -Match "(Cannot convert value '.*?' to type 'System\.Version'\.|must have exactly 3 parts for a Prerelease string|Please ensure that only characters)"
    }

    It "Invalid syntax 'ModuleCannotContainPrerelease' for 'module-to-cache' or 'module-to-cache-prerelease' parameter." {
      $Params = @{Modules = "PnP.PowerShell:1.11.22-nightly"; Shells = "pwsh"; Updatable = $false }
      $ActionParameters = New-ModuleCacheParameter @Params
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester

      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -Match "^A module name into 'module-to-cache' cannot contain a prerelease version"
    }

    It "Invalid syntax 'ModuleMustContainPrerelease' for 'module-to-cache-prerelease' parameter." {
      $Params = @{PrereleaseModules = "PnP.PowerShell:1.11.22"; Shells = "powershell"; Updatable = $false }
      $ActionParameters = New-ModuleCacheParameter @Params
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester

      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -Match "^A module name into 'module-to-cache-prerelease' must contain a prerelease version"
    }
  }
}