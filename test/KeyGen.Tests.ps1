#KeyGen.Tests.ps1
#Checks the 'module-to-cache' or/and 'module-to-cache-prerelease' parameters of the Action and the possible syntax errors.

$ModuleToCacheBasic = @(
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'powershell'; Updatable = $False }
  @{Modules = ''; PrereleaseModules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $False }

  @{Modules = 'PSScriptAnalyzer'; Shells = 'powershell'; Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = ''; Shells = 'pwsh'; Updatable = $False }


  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = 'InvokeBuild'; Shells = 'powershell'; Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; PrereleaseModules = 'InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $False }

  @{Modules = 'ActiveDirectoryCmdlets:22.0.8462.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'ActiveDirectoryCmdlets::'; Shells = 'powershell,pwsh'; Updatable = $True }

  @{Modules = 'PSScriptAnalyzer:1.20.0,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer:1.20.0,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $False }

  @{Modules = 'PSScriptAnalyzer:1.20.0,PnP.PowerShell::,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PSScriptAnalyzer,PnP.PowerShell::,DTW.PS.FileSystem::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PnP.PowerShell:1.11.22-nightly,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = "PSScriptAnalyzer,PnP.PowerShell:1.11.22-nightly,DTW.PS.FileSystem"; Shells = "powershell,pwsh"; Updatable = $true }
  @{PrereleaseModules = "PnP.PowerShell:1.11.22-nightly"; Shells = "powershell, pwsh"; Updatable = $true }

  #syntaxe RQMN
  @{Modules = 'PSGallery\PSScriptAnalyzer,PSGallery\InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'PSGallery\PSScriptAnalyzer:1.20.0,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{PrereleaseModules = 'PSGallery\PSScriptAnalyzer:1.20.0,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{PrereleaseModules = 'PSGallery\InvokeBuild::'; Shells = 'powershell'; Updatable = $true }
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

$ModuleNameWithInvalidChars = @(
  @{Modules = 'PSGallery\Active*:22.0.8462.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'PS*\ActiveDirectoryCmdlets:22.0.8462.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{PrereleaseModules = "PSScript?nalyzer::"; Shells = "powershell, pwsh"; Updatable = $true }
  @{Modules = "/PSScriptAnalyzer::"; PrereleaseModules = "PSScriptAnalyzer>:1.20.0"; Shells = "powershell, pwsh"; Updatable = $true }
  @{Modules = 'InvokeBuild:5.9.0::,PS*::'; PrereleaseModules = "PSScript|Analyzer"; Shells = 'powershell,pwsh'; Updatable = $true }
)

$ModuleToCacheModuleNameWithSpace = @(
  @{Modules = 'ActiveDirectoryCmdlets :22.0.8462.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'ActiveDirectoryCmdlets ::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'PSGallery\ActiveDirectoryCmdlets :22.0.8462.1'; Shells = 'powershell,pwsh'; Updatable = $False }
  @{Modules = 'PSGallery\ActiveDirectoryCmdlets ::'; Shells = 'powershell,pwsh'; Updatable = $true }

  # The scriptblock '$sbToArray' manage the following case
  #@{Modules = 'ActiveDirectoryCmdlets ,InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $false }
)

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
  @{Modules = "dbatools.library:."; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer:1"; Shells = "pwsh"; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer:1."; Shells = "powershell "; Updatable = $false }
  @{Modules = "PSScriptAnalyzer:1."; Shells = "powershell "; Updatable = $false }
  @{PrereleaseModules = "PSScriptAnalyzer:Test"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools.library:1.0-alpha"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools.library:1.0.0.0-alpha"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools.library:1.0.0-alpha.4"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools.library:1.0.0-alpha+4"; Shells = " powershell,pwsh "; Updatable = $false }
  @{PrereleaseModules = "dbatools.library:1.0.0-alpha-4"; Shells = " powershell,pwsh "; Updatable = $false }

  #Semver with constraint
  @{Modules = "dbatools.library:=0.2.3"; Shells = " powershell,pwsh "; Updatable = $false }
  @{Modules = "PnP.PowerShell:!=2.0.0+build.1848"; Shells = "powershell, pwsh"; Updatable = $false }
  @{PrereleaseModules = "dbatools.library:=0.2.3"; Shells = " powershell,pwsh "; Updatable = $false }
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
  @{PrereleaseModules = "dbatools.library::2022.10.25.1"; Shells = "powershell"; Updatable = $true }


  @{Modules = "PSScriptAnalyzer::1"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::1."; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::1.20"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::1.20.0"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "PSScriptAnalyzer::texte"; Shells = "pwsh"; Updatable = $true }
  @{Modules = "dbatools.library::2022.10.25.1"; Shells = "powershell"; Updatable = $true }
)

$ModuleToCacheUnknownModuleName = @(
  @{Modules = 'NotExist::'; Shells = 'powershell'; Updatable = $true; PrefixIdentifier = $false }
  @{Modules = 'NotExist'; Shells = 'powershell'; Updatable = $false; PrefixIdentifier = $true }

  @{PrereleaseModules = 'NotExist::'; Shells = 'powershell,pwsh'; Updatable = $true; PrefixIdentifier = $true }
  @{PrereleaseModules = 'NotExist'; Shells = 'powershell,pwsh'; Updatable = $false; PrefixIdentifier = $false }

  # see RQMN
  @{Modules = 'PSGallery\NotExist::'; Shells = 'powershell'; Updatable = $true; PrefixIdentifier = $false }
  @{Modules = 'PSGallery\NotExist'; Shells = 'powershell'; Updatable = $false; PrefixIdentifier = $true }

  @{PrereleaseModules = 'PSGallery\NotExist::'; Shells = 'powershell,pwsh'; Updatable = $true; PrefixIdentifier = $true }
  @{PrereleaseModules = 'PSGallery\NotExist'; Shells = 'powershell,pwsh'; Updatable = $false; PrefixIdentifier = $false }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

$PSRepositoryExist = Test-PsRepository 'OttoMatt'
if ($PSRepositoryExist -eq $false) {
  Throw "The PsRepository 'OttoMatt' must exist."
}


Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'KeyGen' {

  Context "Syntax for the 'module-to-cache' or 'module-to-cache-prerelease' parameter." {
    It "Syntax for the 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>' / Shells <Shells>" -TestCases @($ModuleToCacheBasic; $ModuleToCacheValidVersion) {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      {
        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        Get-ModuleCache $ActionParameters -Pester > $null
      } | Should -Not -Throw
    }
  }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'KeyGen' {

  Context "Invalid syntax for 'module-to-cache' or 'module-to-cache-prerelease' parameter" {

    It "The module name contains invalid char '<Modules>' / '<PrereleaseModules>' " -TestCases $ModuleNameWithInvalidChars {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -BeGreaterThan 0
      if ( $ErrorModulesCache.Count -eq 1)
      { $ErrorModulesCache[0] | Should -Match "contains one or more invalid characters" }

      if ( $ErrorModulesCache.Count -eq 2) {
        $ErrorModulesCache[0] | Should -Match "contains one or more invalid characters"
        $ErrorModulesCache[1] | Should -Match "contains one or more invalid characters"
      }

      if ( $ErrorModulesCache.Count -eq 3) {
        $ErrorModulesCache[0] | Should -Match "contains one or more invalid characters"
        $ErrorModulesCache[1] | Should -Match "contains one or more invalid characters"
        $ErrorModulesCache[2] | Should -Match "contains one or more invalid characters"
      }
    }

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
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^An immutable cache cannot contain updatable cache information"
    }

    It "Invalid syntax 'UpdatableCacheMustContainUpdatableInformation' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheUpdatableCacheMustContainUpdatableInformation {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^An updatable cache must contain cache information"
    }

    It "Invalid syntax 'EmptyModuleName' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheEmptyModuleName {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      if ($ErrorModulesCache.Count -eq 1)
      { $ErrorModulesCache[0] | Should -Match 'A module name is empty for' }
      if ($ErrorModulesCache.Count -eq 2) {
        $ErrorModulesCache[0] | Should -Match 'A module name is empty for'
        $ErrorModulesCache[1] | Should -Match 'A module name is empty for'
      }
      if ($ErrorModulesCache.Count -eq 3) {
        $ErrorModulesCache[0] | Should -Match 'A module name is empty for'
        $ErrorModulesCache[1] | Should -Match 'A module name is empty for'
        $ErrorModulesCache[2] | Should -Match 'A module name is empty for'
      } else { $ErrorModulesCache.Count | Should -Not -BeGreaterThan 4 }
    }

    It "Invalid syntax when a module name contains a 'space' character.  '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheModuleNameWithSpace {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^Find-Package: No match was found for the specified search criteria"
    }


    It "Invalid syntax 'UpdatableModuleCannotContainVersionInformation' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheUpdatableModuleCannotContainVersionInformation {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^An updatable module must not specify a version number"
    }

    It "Invalid syntax 'MissingRequiredVersion' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheMissingRequiredVersion {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      if ($ErrorModulesCache.Count -eq 1)
      { $ErrorModulesCache[0] | Should -Match $global:PSModuleCacheResources.MissingRequiredVersion }
      if ($ErrorModulesCache.Count -eq 2) {
        $ErrorModulesCache[0] | Should -Match $global:PSModuleCacheResources.MissingRequiredVersion
        $ErrorModulesCache[1] | Should -Match $global:PSModuleCacheResources.MissingRequiredVersion
      } else { $ErrorModulesCache.Count | Should -Not -BeGreaterThan 3 }
    }

    It "Invalid syntax 'UnknownModuleName' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheUnknownModuleName {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^Find-Package: No match was found for the specified search criteria"
    }

    It "Invalid syntax 'InvalidVersionNumberSyntax' for 'module-to-cache' or 'module-to-cache-prerelease' parameter with '<Modules>' / '<PrereleaseModules>'" -TestCases $ModuleToCacheInvalidVersionNumberSyntax {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 2
      $ErrorModulesCache[1] | Should -Match '^The syntax of the version'
      $ErrorModulesCache[0] | Should -Match "(Cannot convert value '.*?' to type 'System\.Version'\.|must have exactly 3 parts for a Prerelease string|Please ensure that only characters)"
    }

    It "Invalid syntax 'ModuleCannotContainPrerelease' for 'module-to-cache' or 'module-to-cache-prerelease' parameter." {
      $Params = @{Modules = "PnP.PowerShell:1.11.22-nightly"; Shells = "pwsh"; Updatable = $false }
      $ActionParameters = New-ModuleCacheParameter @Params
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester

      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^A module name into 'module-to-cache' cannot contain a prerelease version"
    }

    It "Invalid syntax 'ModuleMustContainPrerelease' for 'module-to-cache-prerelease' parameter." {
      $Params = @{PrereleaseModules = "PnP.PowerShell:1.11.22"; Shells = "powershell"; Updatable = $false }
      $ActionParameters = New-ModuleCacheParameter @Params
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester

      $ErrorModulesCache.Count | Should -Be 1
      $ErrorModulesCache[0] | Should -Match "^A module name into 'module-to-cache-prerelease' must contain a prerelease version"
    }
  }
}