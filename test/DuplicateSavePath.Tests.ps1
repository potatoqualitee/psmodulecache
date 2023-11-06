
#DuplicateSavePath.Tests.ps1
#Checks the duplication of module save path.

$global:WithSavePathDuplication = @(
   #!! RULE On laisse la possibilité d'installer un module 'X' V1.0.0 de psgallery et un module 'X' V1.0.0-beta de MyGet
   @{Modules = 'PSModuleCache\lowercase:0.0.1'; PrereleaseModules = 'OttoMatt\lowercase:1.0.0-beta'; Shells = 'powershell,pwsh'; Updatable = $false }
)

$global:DelayedDuplication = @(
   #!!There are no duplicates during the first analysis but there are once the repositories have been queried,
   #!! the 'Remove-ModulePathDuplication' function will be responsible for removing these duplicates.
   @{Modules = 'LatestStableVersion:2.0.0'; PrereleaseModules = 'LatestStableVersion::'; Shells = 'powershell, pwsh'; Updatable = $true }

   #!!Prerequisite: there are several repositories
   #see $DuplicationWhenOnlyOneRepositoryExist into 'ModuleNameDuplication.Tests.ps1'
   @{Modules = 'PSGallery\InvokeBuild:5.9.0,Invokebuild:5.9.0'; Shells = 'powershell, pwsh'; Updatable = $false }
   @{Modules = 'PsGallery\Pester,Pester'; Shells = 'powershell, pwsh'; Updatable = $false }
   @{Modules = 'PsGallery\Pester,Pester::'; Shells = 'powershell, pwsh'; Updatable = $true }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'DuplicateSavePath' {

   Context "The action parameter returns single modules." {
      It "We retrieve the same module version twice (one stable and one prerelease) - no dependency." {
         $Params = @{Modules = 'Pester:5.0.0'; PrereleaseModules = 'Pester:5.1.0-beta1'; Shells = 'powershell,pwsh'; Updatable = $false }

         $ActionParameters = New-ModuleCacheParameter @params
         $ModulesCache = Get-ModuleCache $ActionParameters

         $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 2
         $ModulesCache.ModuleCacheInformations[0].Name | Should -Be 'Pester'
         $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 0

         InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
            $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI
            $Result.Count | Should -Be 2
            $Result[0].Repository | Should -Be 'PSGallery'
            $Result[1].Repository | Should -Be 'PSGallery'
         }
      }

      It "We retrieve two modules and their dependencies, no duplication." {
         $params = @{Modules = 'PsModuleCache\Duplicate,PsModuleCache\String'; Shells = 'powershell,pwsh'; Updatable = $false }

         $ActionParameters = New-ModuleCacheParameter @params
         $ModulesCache = Get-ModuleCache $ActionParameters

         $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 2

         $ModulesCache.ModuleCacheInformations[0].Name | Should -Be 'Duplicate'
         $ModulesCache.ModuleCacheInformations[1].Name | Should -Be 'String'
         $ModulesCache.ModuleCacheInformations[1].Version | Should -Be '3.0.0'

         $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 2
         $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be 1

         InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
            $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI | Sort-Object Name, Version
            $Result.Count | Should -Be 5

            [System.Predicate[Object]]$Predicate = {
               Param($Module)
               $Module.Repository -eq 'PSModuleCache'
            }
            [Array]::TrueForAll($Result, $Predicate) | Should -Be $true

            $Result[0].Name | Should -Be 'Duplicate'
            $Result[0].Version | Should -Be '1.0.0'
            $Result[0].MainModule | Should -Be $null

            $Result[1].Name | Should -Be 'lowercase'
            $Result[1].Version | Should -Be '2.0.0'
            $Result[1].MainModule | Should -Be 'psmodulecache-String-3.0.0'

            $Result[2].Name | Should -Be 'String'
            $Result[2].Version | Should -Be '1.0.0'
            $Result[2].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'

            $Result[3].Name | Should -Be 'String'
            $Result[3].Version | Should -Be '3.0.0'
            $Result[3].MainModule | Should -Be $null

            $Result[4].Name | Should -Be 'UpperCase'
            $Result[4].Version | Should -Be '1.0.0'
            $Result[4].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'

         }
      }

      It "We retrieve two modules and their dependencies, the 'String' module exists in two repositories. No duplication." {
         #Two versions for 'string' with different GUIDs
         #We let the user control the consistency of what they configure
         $params = @{Modules = 'PSModuleCache\Duplicate,psgallery\string'; Shells = 'powershell,pwsh'; Updatable = $false }

         $ActionParameters = New-ModuleCacheParameter @params
         $ModulesCache = Get-ModuleCache $ActionParameters

         $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 2

         $ModulesCache.ModuleCacheInformations[1].Name | Should -Be 'Duplicate'
         $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'string'
         $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '1.1.3'
         $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'

         $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 0
         $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be 2

         InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
            $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI | Sort-Object Name, Version
            $Result.Count | Should -Be 4

            $Result[0].Name | Should -Be 'Duplicate'
            $Result[0].Version | Should -Be '1.0.0'
            $Result[0].MainModule | Should -Be $null

            $Result[1].Name | Should -MatchExactly 'String'
            $Result[1].Version | Should -Be '1.0.0'
            $Result[1].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'

            $Result[2].Name | Should -MatchExactly 'string'
            $Result[2].Version | Should -Be '1.1.3'
            $Result[2].MainModule | Should -Be $null

            $Result[3].Name | Should -Be 'UpperCase'
            $Result[3].Version | Should -Be '1.0.0'
            $Result[3].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'
         }
      }

      #Skip : Searching via find-module for 'Az' modules takes 3mn30.
      #We check this operation in a workflow
      It "We retrieve 'AZ' modules version 9.3.0 and its dependencies, the duplicated 'AZ.Account' modules are removed."  -Skip:( (Test-Path env:CI) -eq $false) {
         $params = @{Modules = 'Az:9.3.0,Az:10.4.1'; Shells = 'powershell,pwsh'; Updatable = $false }

         $ActionParameters = New-ModuleCacheParameter @params
         $ModulesCache = Get-ModuleCache $ActionParameters

         $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 2

         #This following call returns 108 modules including 26 times the 'AZ.Account' module :
         #"Find-Module -name 'AZ' -IncludeDependencies -RequiredVersion' 10.4.1"
         #We subtract -1 for the primary module.
         #
         #The 'Remove-ModuleDependencyDuplicate' function filters duplicate dependencies returned by Find-Module.
         $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '10.4.1'
         $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be ( (108 - 25) - 1)

         $ModulesCache.ModuleCacheInformations[1].Version | Should -Be '9.3.0'
         $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be ( (105 - 27) - 1)

         <#
         todo controle dans inScopeModule
         $result = &$mod { Remove-ModulePathDuplication  $ModulesCache.ModuleCacheInformations }
         $h = $result | Sort-Object Name | Group-Object Name -AsHashTable
         $h.'Az.Storage'

         #PSGallery-Az-9.3.0  Az.Storage 5.3.0   PSGallery
         #PSGallery-Az-10.4.1 Az.Storage 5.10.1  PSGallery


         $h.'Az.Storagemover'
         #PSGallery-Az-10.4.1 Az.StorageMover 1.0.1   PSGallery
         #>
      }
   }

   Context "The action setting return duplicate modules (name AND version)." {
      It "We retrieve the same module version twice (one stable and one prerelease) - each version references the same dependency." {
         $params = @{Modules = 'LatestPrereleaseVersion'; PrereleaseModules = 'LatestPrereleaseVersion'; Shells = 'powershell,pwsh'; Updatable = $false }

         $ActionParameters = New-ModuleCacheParameter @params
         $ModulesCache = Get-ModuleCache $ActionParameters
         $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 2

         $ModulesCache.ModuleCacheInformations[0].Name | Should -Be 'LatestPrereleaseVersion'
         $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '1.0.0'

         $ModulesCache.ModuleCacheInformations[1].Name | Should -Be 'LatestPrereleaseVersion'
         $ModulesCache.ModuleCacheInformations[1].Version | Should -Be '2.0.0-beta'

         $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 1
         $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be 1

         $ModulesCache.ModuleCacheInformations[0].Dependencies[0].Name | Should -Be 'UpperCase'
         $ModulesCache.ModuleCacheInformations[0].Dependencies[0].Version | Should -Be '1.0.0'

         $ModulesCache.ModuleCacheInformations[1].Dependencies[0].Name | Should -Be 'UpperCase'
         $ModulesCache.ModuleCacheInformations[1].Dependencies[0].Version | Should -Be '1.0.0'


         InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
            $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI | Sort-Object Name, Version
            $Result.Count | Should -Be 3

            [System.Predicate[Object]]$Predicate = {
               Param($Module)
               $Module.Repository -eq 'PSModuleCache'
            }
            [Array]::TrueForAll($Result, $Predicate) | Should -Be $true

            $Result[0].Name | Should -Be 'LatestPrereleaseVersion'
            $Result[0].Version | Should -Be '1.0.0'

            $Result[1].Name | Should -Be 'LatestPrereleaseVersion'
            $Result[1].Version | Should -Be '2.0.0-beta'

            $Result[2].Name | Should -Be 'UpperCase'
            $Result[2].Version | Should -Be '1.0.0'
         }
      }

      It "We retrieve the same module version twice and the dependency twice." {
         $params = @{Modules = 'LatestStableVersion'; PrereleaseModules = 'LatestStableVersion::'; Shells = 'powershell,pwsh'; Updatable = $true }

         $ActionParameters = New-ModuleCacheParameter @params
         $ModulesCache = Get-ModuleCache $ActionParameters

         $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
         $ModulesCache.ModuleCacheInformations[0].Name | Should -Be 'LatestStableVersion'
         $ModulesCache.ModuleCacheInformations[0].Version  | Should -Be '2.0.0'
         $ModulesCache.ModuleCacheInformations[1].Name | Should -Be 'LatestStableVersion'
         $ModulesCache.ModuleCacheInformations[1].Version  | Should -Be '2.0.0'


         $ModulesCache.ModuleCacheInformations.Count | Should -Be 2
         $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 1
         $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be 1

         $ModulesCache.ModuleCacheInformations[0].Dependencies[0].Name  | Should -Be 'UpperCase'
         $ModulesCache.ModuleCacheInformations[0].Dependencies[0].Version  | Should -Be '1.0.0'
         $ModulesCache.ModuleCacheInformations[1].Dependencies[0].Name  | Should -Be 'UpperCase'
         $ModulesCache.ModuleCacheInformations[1].Dependencies[0].Version  | Should -Be '1.0.0'


         InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
            $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI | Sort-Object Name, Version
            $Result.Count | Should -Be 2

            $Result[0].Name | Should -Be 'LatestStableVersion'
            $Result[0].Version | Should -Be '2.0.0'
            $Result[0].Repository | Should -Be 'PSModuleCache'

            $Result[1].Name | Should -Be 'UpperCase'
            $Result[1].Version  | Should -Be '1.0.0'
            $Result[1].Repository | Should -Be 'PSModuleCache'
         }
      }
   }


   It "We retrieve two modules and their dependencies, a primary module is duplicated as dependencies." {
      $params = @{Modules = 'PsModuleCache\Duplicate,PsModuleCache\String:1.0.0'; Shells = 'powershell,pwsh'; Updatable = $false }

      $ActionParameters = New-ModuleCacheParameter @params
      $ModulesCache = Get-ModuleCache $ActionParameters

      $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
      $ModulesCache.ModuleCacheInformations.Count | Should -Be 2

      $ModulesCache.ModuleCacheInformations[0].Name | Should -Be 'Duplicate'

      $ModulesCache.ModuleCacheInformations[1].Name | Should -Be 'String'
      $ModulesCache.ModuleCacheInformations[1].Version | Should -Be '1.0.0'

      $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 2
      $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be 1

      InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
         $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI | Sort-Object Name, Version
         $Result.Count | Should -Be 3

         [System.Predicate[Object]]$Predicate = {
            Param($Module)
            $Module.Repository -eq 'PSModuleCache'
         }
         [Array]::TrueForAll($Result, $Predicate) | Should -Be $true

         $Result[0].Name | Should -Be 'Duplicate'
         $Result[0].Version  | Should -Be '1.0.0'
         $Result[0].MainModule | Should -Be $null

         #We retrieve a dependency instead of a primary module, but the path to save is identical in both cases (same name and same version)
         # other example @{Modules = 'PSModuleCache\Duplicate,Uppercase,String:2.0.0'; Shells = 'powershell,pwsh'; Updatable = $false }
         $Result[1].Name | Should -Be 'String'
         $Result[1].Version | Should -Be '1.0.0'
         $Result[1].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'

         $Result[2].Name | Should -Be 'UpperCase'
         $Result[2].Version | Should -Be '1.0.0'
         $Result[2].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'
      }
   }


   It "We retrieve two modules and their dependencies, one dependency is duplicated and there are two separate dependencies of the 'String' module." {
      $params = @{Modules = 'PsModuleCache\Duplicate,PsModuleCache\Example'; Shells = 'powershell,pwsh'; Updatable = $false }

      $ActionParameters = New-ModuleCacheParameter @params
      $ModulesCache = Get-ModuleCache $ActionParameters

      $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
      $ModulesCache.ModuleCacheInformations.Count | Should -Be 2

      $ModulesCache.ModuleCacheInformations[0].Name | Should -Be 'Duplicate'

      $ModulesCache.ModuleCacheInformations[1].Name | Should -Be 'Example'
      $ModulesCache.ModuleCacheInformations[1].Version | Should -Be '1.0.0'

      $ModulesCache.ModuleCacheInformations[0].Dependencies.Count | Should -Be 2
      $ModulesCache.ModuleCacheInformations[1].Dependencies.Count | Should -Be 2

      InModuleScope 'PsModuleCache' -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations } {
         $Result = Remove-ModulePathDuplication -ModuleCacheInformations $MCI | Sort-Object Name, Version
         $Result.Count | Should -Be 5

         [System.Predicate[Object]]$Predicate = {
            Param($Module)
            $Module.Repository -eq 'PSModuleCache'
         }
         [Array]::TrueForAll($Result, $Predicate) | Should -Be $true

         $Result[0].Name | Should -Be 'Duplicate'
         $Result[0].Version  | Should -Be '1.0.0'
         $Result[0].MainModule | Should -Be $null

         $Result[1].Name | Should -Be 'Example'
         $Result[1].Version | Should -Be '1.0.0'
         $Result[1].MainModule | Should -Be $null

         $Result[2].Name | Should -Be 'String'
         $Result[2].Version | Should -Be '1.0.0'
         $Result[2].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'

         $Result[3].Name | Should -Be 'String'
         $Result[3].Version | Should -Be '2.0.0'
         $Result[3].MainModule | Should -Be 'psmodulecache-Example-1.0.0'

         $Result[4].Name | Should -Be 'UpperCase'
         $Result[4].Version | Should -Be '1.0.0'
         $Result[4].MainModule | Should -Be 'psmodulecache-Duplicate-1.0.0'
      }
   }
}

