
#ModuleNameDuplication.Tests.ps1
#Checks the duplication of module names for 'modules-to-cache' and 'modules-to-cache-prerelease' parameter.

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

$global:DuplicateStable = @(
  @{Modules = 'Main,MAIN'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'PSGallery\Main,PSGallery\Main'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{Modules = 'Main::,Main::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'PSGallery\Main::,PSGallery\Main::'; Shells = 'powershell,pwsh'; Updatable = $true }

  @{Modules = 'InvokeBuild:5.9.0,Invokebuild:5.9.0'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'PSGallery\InvokeBuild:5.9.0,PSGallery\Invokebuild:5.9.0'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{Modules = 'Main,Main::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'PSGallery\Main,PSGallery\Main::'; Shells = 'powershell,pwsh'; Updatable = $true }
)


$global:DuplicatePrerelease = @(
  @{PrereleaseModules = 'String,sTRING'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{PrereleaseModules = 'PSGallery\String,PSGallery\String'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{PrereleaseModules = 'String::,String::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PSGallery\String::,PSGallery\String::'; Shells = 'powershell,pwsh'; Updatable = $true }


  @{PrereleaseModules = 'PnP.PowerShell:1.11.22-nightly,PnP.PowerShell:1.11.22-nightly'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{PrereleaseModules = 'PSGallery\PnP.PowerShell:1.11.22-nightly,PSGallery\PnP.PowerShell:1.11.22-nightly'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{PrereleaseModules = 'String,String::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PSGallery\String,PSGallery\String::'; Shells = 'powershell,pwsh'; Updatable = $true }
)

$global:DuplicationWhenOnlyOneRepositoryExist = @(
  @{Modules = 'PSGallery\InvokeBuild:5.9.0,Invokebuild:5.9.0'; Shells = 'powershell, pwsh'; Updatable = $false }
  @{Modules = 'PsGallery\Pester,Pester'; Shells = 'powershell, pwsh'; Updatable = $false }
  @{Modules = 'PsGallery\Pester,Pester::'; Shells = 'powershell, pwsh'; Updatable = $true }
)

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'ModuleNameDuplication' {
  Context 'Check module names duplication' {

    It "'modules-to-cache' parameter contains duplicate module names : '<Modules>'" -TestCases $global:DuplicateStable {
      param(
        $Modules,
        $Shells,
        [switch]$Updatable
      )

      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      #The setting can trigger several errors but only the first one interests us here
      $ErrorModulesCache.Count | Should -Ge 1
      $ErrorModulesCache[0] | Should -Match "^The 'modules-to-cache' parameter contains duplicated module names"
    }

    It "'modules-to-cache-prerelease' parameter contains duplicate module names : '<PrereleaseModules>'" -TestCases $global:DuplicatePrerelease {
      param(
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )

      $ActionParameters = New-ModuleCacheParameter -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      #The setting can trigger several errors but only the first one interests us here
      $ErrorModulesCache.Count | Should -Ge 1
      $ErrorModulesCache[0] | Should -Match "^The 'modules-to-cache-prerelease' parameter contains duplicated module names"
    }

    It "more than one repository is registered. 'modules-to-cache' parameter not contains duplicate module names : '<Modules>'" -TestCases $global:DuplicationWhenOnlyOneRepositoryExist {
      param(

        $Modules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells -Updatable:$Updatable
      $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ErrorModulesCache.Count | Should -Be 0
    }

    It "Only PsGallery is registered. 'modules-to-cache' parameter contains duplicate module names : '<Modules>'" -TestCases $global:DuplicationWhenOnlyOneRepositoryExist {
      param(
        $Modules,
        $Shells,
        [switch]$Updatable
      )
      try {
        . "$PSScriptRoot/Dependencies/UnRegister-TestRepository.ps1"
        #Avoid bug : NullReferenceException: Object reference not set to an instance of an object. (...\PSModuleCache.psm1:36)
        Remove-Module PSModuleCache -Force
        #Update the $RepositoryNames variable
        Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells -Updatable:$Updatable
        $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
        #The setting can trigger several errors but only the first one interests us here
        $ErrorModulesCache.Count | Should -Be 1
        $ErrorModulesCache[0] | Should -Match "^The 'modules-to-cache' parameter contains duplicated module names"

      } finally {
        . "$PSScriptRoot\Dependencies\Register-TestRepository.ps1"
        Remove-Module PSModuleCache -Force
        Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force
      }
    }
  }
}
