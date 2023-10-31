#Dependency.Tests.ps1
#Retrieve the dependencies of a module name.
#We only check the list of dependencies of a module. The consistency of the backup is controlled by the script 'DuplicateSavePath.Tests.ps1'

<#
NOTE:
 !!! The contents of the repositories will influence the result of the tests

 In a module specification the identity, and uniqueness, of a module is based on (Name,Version,GUID).
 In a Nuget repository the GUID is not used because the identity, and uniqueness, is based on the name and version (which make up its ID).
 We can therefore have 2 modules of the same name with a different GUID, but they must be in two repositories and be installed in separate directories (psmodulepath).
 See to : https://github.com/PowerShell/PowerShellGet/issues/20

 An object returned by Find-Module does not contain the module GUID, but the name of the repository in which it was found.
#>

#External dependencies
# ExternalModuleDependencies : Find-module -Name external -IncludeDependencies do not return external dependencies.
# voir :
# https://stackoverflow.com/questions/55668072/how-to-cause-install-module-to-also-install-any-required-modules


$global:ModuleDepend = @(
  @{Modules = 'PsModuleCache\Depends'; Shells = 'powershell,pwsh'; Updatable = $false; Dependencies = @('Tools') }
  @{Modules = 'PsModuleCache\Depends::'; Shells = 'powershell,pwsh'; Updatable = $true; Dependencies = @('Tools') }

  @{PrereleaseModules = 'PsModuleCache\Depends'; Shells = 'powershell,pwsh'; Updatable = $false; Dependencies = @('Tools') }
  @{PrereleaseModules = 'PsModuleCache\Depends::'; Shells = 'powershell'; Updatable = $true; Dependencies = @('Tools') }
)

$global:ModuleDuplicate = @(
  @{Modules = 'PsModuleCache\Duplicate'; Shells = 'powershell,pwsh'; Updatable = $false; Dependencies = @('String', 'UpperCase') }
  @{Modules = 'PsModuleCache\Duplicate::'; Shells = 'powershell,pwsh'; Updatable = $true; Dependencies = @('String', 'UpperCase') }

  @{PrereleaseModules = 'PsModuleCache\Duplicate'; Shells = 'powershell,pwsh'; Updatable = $false; Dependencies = @('String', 'UpperCase') }
  @{PrereleaseModules = 'PsModuleCache\Duplicate:: '; Shells = 'powershell,pwsh'; Updatable = $true; Dependencies = @('String', 'UpperCase') }
)

$global:ModuleDuplicateByDependency = @(
  @{Modules = 'PsModuleCache\DuplicateByDependency'; Shells = 'powershell,pwsh'; Updatable = $false; Dependencies = @('Main', 'Duplicate', 'String', 'UpperCase') }
  @{Modules = 'PsModuleCache\DuplicateByDependency::'; Shells = 'powershell,pwsh'; Updatable = $true; Dependencies = @('Main', 'Duplicate', 'String', 'UpperCase') }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

$PSRepositoryExist = Test-PsRepository 'PSModuleCache'
if ($PSRepositoryExist -eq $false) {
  Throw "The PsRepository 'PSModuleCache' must exist."
}

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'Dependencies' {

  Context "Retrieve modules dependencies." {
    It "The 'Tools' module has no dependencies." {
      $params = @{Modules = 'PSModulecache\Tools'; Shells = 'powershell,pwsh'; Updatable = $false }

      $ActionParameters = New-ModuleCacheParameter @params
      $ModulesCache = Get-ModuleCache $ActionParameters
      $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'Tools' }
      $MainModule.Dependencies.Count | Should -Be 0
    }

    It "Retrieve the dependencies of the module 'String' from PsGallery." {
      $ActionParameters = New-ModuleCacheParameter -Modules 'PSGallery\String' -Shells 'pwsh'
      $ModulesCache = Get-ModuleCache $ActionParameters
      $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'String' }
      $MainModule.Dependencies.Count | Should -Be 0
    }

    It "Retrieve the dependencies of the module 'String' from PsModulecache." {
      $ActionParameters = New-ModuleCacheParameter -Modules 'PsModulecache\String' -Shells 'pwsh'
      $ModulesCache = Get-ModuleCache $ActionParameters
      $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'String' }
      $MainModule.Dependencies.Count | Should -Be 1

      $MainModule.Dependencies[0].MainModule | Should -Be 'psmodulecache-String-3.0.0'
      $MainModule.Dependencies[0].Name | Should -Be 'lowercase'
      $MainModule.Dependencies[0].Version | Should -Be '2.0.0'
      $MainModule.Dependencies[0].Repository | Should -Be 'psmodulecache'
    }

    It "Retrieve the dependencies of the module 'Depend' = '<Dependencies>'." -TestCases $global:ModuleDepend {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable,
        $Dependencies
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters
      $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'Depends' }
      $MainModule.Dependencies.Count | Should -Be 1

      $MainModule.Dependencies[0].MainModule | Should -Be 'psmodulecache-Depends-1.0.0'
      $MainModule.Dependencies[0].Name | Should -Be 'Tools'
      $MainModule.Dependencies[0].Version | Should -Be '1.0.0'
      $MainModule.Dependencies[0].Repository | Should -Be 'psmodulecache'
    }

    It "Retrieve the dependencies of the module 'Duplicate' = '<Dependencies>'." -TestCases $global:ModuleDuplicate {
      #'psmodulecache' repository contains 'Duplicate' module
      #'PSGallery' repository contains 'string' module

      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters
      $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'Duplicate' }
      $MainModule.Dependencies.Count | Should -Be 2

      [System.Predicate[Object]]$Predicate = {
        Param($Module)
        $Module.Repository -eq 'PSModuleCache'
        ($Module.Repository -eq 'PSModuleCache') -and ($Module.MainModule -eq 'psmodulecache-Duplicate-1.0.0') -and ( $Module.Version -eq '1.0.0')
      }
      [Array]::TrueForAll(([Object[]]$MainModule.Dependencies), $Predicate) | Should -Be $true

      $MainModule.Dependencies[0].Name | Should -Be 'String'

      $MainModule.Dependencies[1].Name | Should -Be 'UpperCase'
    }

    It "Retrieve the dependencies of the module 'DuplicateByDependency' = '<Dependencies>'." -TestCases $global:ModuleDuplicateByDependency {
      #'psmodulecache' repository contains 'Duplicate' module
      #'PSGallery' repository contains 'string' module

      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters
      $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'DuplicateByDependency' }

      $MainModule.Dependencies.Count | Should -Be 4

      [System.Predicate[Object]]$Predicate = {
        Param($Module)
        ($Module.Repository -eq 'PSModuleCache') -and ($Module.MainModule -eq 'psmodulecache-DuplicateByDependency-1.0.0') -and ( $Module.Version -eq '1.0.0')
      }
      [Array]::TrueForAll(([Object[]]$MainModule.Dependencies), $Predicate) | Should -Be $true
    }
  }
}
