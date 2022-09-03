#GHA.PSmoduleCache.ModuleVersion.Tests.ps1
# Tests the version number of a module according to search criteria

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Tests the version number of a module according to search criteria. When there is no error.' -Tag 'ModuleVersion' {

  Context "Updatable module" {
    it "use 'modules-to-cache', we save the last stable version" {
      InModuleScope 'PsModuleCache' {
         $ActionParameters=New-ModuleCacheParameter -Modules 'PnP.PowerShell::' -Shells 'powershell' -Updatable
         $ModulesCache=Get-ModuleCache $ActionParameters
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 1
         #We check if the version number is not a prerelease.
         Test-PrereleaseVersion $ModulesCache.ModuleCacheInformations.Version| Should -be $false
      }
    }

    it "use 'modules-to-cache-prerelease', we save the last stable version" {
      InModuleScope 'PsModuleCache' {
         $ActionParameters=New-ModuleCacheParameter -PrereleaseModules 'PnP.PowerShell::'  -Shells 'powershell' -Updatable
         $ModulesCache=Get-ModuleCache $ActionParameters
         $ModulesCache.ModuleCacheInformations.Count | Should -Be 1
         #We check if the version number is a prerelease.
         Test-PrereleaseVersion $ModulesCache.ModuleCacheInformations.Version| Should -be $true
      }
    }
   }
}

#todo ordre d'exécution
Describe 'Tests the version number of a module according to search criteria. When there error.' -Tag 'ModuleVersion' {

   Context "Updatable module" {
     it "use 'modules-to-cache', the module name is unknown" {
       InModuleScope 'PsModuleCache' {
          $ActionParameters=New-ModuleCacheParameter -Modules 'NotExist' -Shells 'pwsh' -Prefixidentifier
          $ModulesCache=Get-ModuleCache $ActionParameters
          $ModulesCache.ModuleCacheInformations.Count | Should -Be 1
          $null = $ModulesCache | Export-CliXml -Path (Join-Path $home -ChildPath $CacheFilename)

           # The setting is correct, but the creation of the cache will fail, because the module do not exist.
           try {
            $Old,$WarningPreference=$WarningPreference,'SilentlyContinue'
           { Save-ModuleCache }|Should -Throw
           } finally {
             $WarningPreference=$Old
           }
          $script:FunctionnalErrors.Count | Should -Be 1
          $script:FunctionnalErrors[0] | Should -match "^Find-Package: No match was found for the specified search criteria"
       }
     }

     it "use 'modules-to-cache', the module name exist but not the version" {
       InModuleScope 'PsModuleCache' {
          $ActionParameters=New-ModuleCacheParameter -Modules 'InvokeBuild:20.2.15' -Shells 'pwsh' -Prefixidentifier
          $ModulesCache=Get-ModuleCache $ActionParameters
          $ModulesCache.ModuleCacheInformations.Count | Should -Be 1
          $null = $ModulesCache | Export-CliXml -Path (Join-Path $home -ChildPath $CacheFilename)

           # The setting is correct, but the creation of the cache will fail,
           # because for this syntax the existence of the module version is only checked when calling Save-ModuleCache.
          try {
           $Old,$WarningPreference=$WarningPreference,'SilentlyContinue'
          { Save-ModuleCache }|Should -Throw
          } finally {
            $WarningPreference=$Old
          }
          $script:FunctionnalErrors.Count | Should -Be 1
          $script:FunctionnalErrors[0] | Should -match "^Find-Package: No match was found for the specified search criteria"
       }
     }
   }

   AfterEach {
      Remove-Item -Path (Join-Path $home -ChildPath $CacheFilename)
  }
}

