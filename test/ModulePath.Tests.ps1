#ModulePath.Tests.ps1
#Checks the construction of the save path names according to the shell and the number of modules.
#we test modules without dependencies.
#!! This module names are sorted

$ModulePathPSWindows = @(
  #1 module
  @{PrereleaseModules = 'InvokeBuild::'; Shells = 'powershell'; Updatable = $true }
  @{Modules = 'InvokeBuild::'; Shells = 'powershell'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'powershell'; Updatable = $false }
  @{Modules = 'InvokeBuild'; Shells = 'powershell'; Updatable = $false }

  #2 modules
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell::'; Shells = 'powershell'; Updatable = $true }
  @{Modules = 'InvokeBuild::,PnP.PowerShell'; Shells = 'powershell'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell'; Shells = 'powershell'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell'; Shells = 'powershell'; Updatable = $false }

  #3 modules
  @{PrereleaseModules = 'DTW.PS.FileSystem::,InvokeBuild,PnP.PowerShell'; Shells = 'powershell'; Updatable = $true }
  @{Modules = 'DTW.PS.FileSystem,InvokeBuild::,PnP.PowerShell'; Shells = 'powershell'; Updatable = $true }
  @{PrereleaseModules = 'DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell'; Shells = 'powershell'; Updatable = $false }
  @{Modules = 'DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell'; Shells = 'powershell'; Updatable = $false }
)

$ModulePathPSCore = @(
  @{PrereleaseModules = 'PSGallery\InvokeBuild::'; Shells = 'pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild::'; Shells = 'pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $false }
  @{Modules = 'PSGallery\InvokeBuild'; Shells = 'pwsh'; Updatable = $false }

  @{PrereleaseModules = 'InvokeBuild::,PSGallery\PnP.PowerShell'; Shells = 'pwsh'; Updatable = $true }
  @{Modules = 'PSGallery\InvokeBuild,PnP.PowerShell::'; Shells = 'pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $false }

  @{PrereleaseModules = 'DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell::'; Shells = 'pwsh'; Updatable = $true }
  @{Modules = 'DTW.PS.FileSystem::,InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $true }
  @{PrereleaseModules = 'DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $false }
  @{Modules = 'DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $false }
)

$ModulePathPSCoreAndWindows = @(
  @{PrereleaseModules = 'InvokeBuild::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{PrereleaseModules = 'InvokeBuild::,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'PSGallery\InvokeBuild,PSGallery\PnP.PowerShell::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'PSGallery\InvokeBuild,PSGallery\PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{PrereleaseModules = 'DTW.PS.FileSystem,PSGallery\InvokeBuild::,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'DTW.PS.FileSystem::,InvokeBuild,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'OttoMatt\DTW.PS.FileSystem,InvokeBuild,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $false }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'ModulePath' {

  Context "Syntax for the 'ModulePath' parameter for Windows Powershell." {
    It "New-ModuleSavePath with '<Modules>' / '<PrereleaseModules>'." -Skip:($isWindows -eq $false) -TestCases $ModulePathPSWindows {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable,
        [switch]$AllowPrerelease
      )
      {
        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ModulesCache = Get-ModuleCache $ActionParameters
        $Paths = @(New-ModuleSavePath $ModulesCache)
        #Module names only
        $ModulesFound = @($ModulesCache.ModuleCacheInformations.Name | Sort-Object)

        #note : The result is coupled to the test set.
        switch ($ModulesFound.Count) {
          #Paths may contain a different numeric version, we only test the parent path.
          1 { $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[0]))) | Should -Be $true }
          2 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[1]))) | Should -Be $true
          }
          3 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[1]))) | Should -Be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[2]))) | Should -Be $true
          }
          default { $Paths.Count | Should -Be -1 }
        }
      } | Should -Not -Throw
    }
  }

  Context "Syntax for the 'ModulePath' parameter for Powershell Core Linux/OSX." {
    It "New-ModuleSavePath with '<Modules>' / '<PrereleaseModules>'." -Skip:($isWindows -eq $true) -TestCases $ModulePathPSCore {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable,
        [switch]$AllowPrerelease
      )
      {
        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ModulesCache = Get-ModuleCache $ActionParameters
        $Paths = @(New-ModuleSavePath $ModulesCache)
        #Under pwsh the Group-object cmdlet returns a sorted result,
        # while under Windows this cmdlet does not sort the objects.
        #Here we do not receive a dependency so we are guaranteed to have the same sort order in $Path and $ModulesFound.
        $ModulesFound = @($ModulesCache.ModuleCacheInformations.Name | Sort-Object)

        switch ($ModulesFound.Count) {
          1 { $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $ModulesFound[0]))) | Should -Be $true }
          2 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $ModulesFound[1]))) | Should -Be $true
          }
          3 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $ModulesFound[1]))) | Should -Be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $ModulesFound[2]))) | Should -Be $true
          }
          default { $Paths.Count | Should -Be -1 }
        }
      } | Should -Not -Throw
    }
  }

  Context "Syntax for the 'ModulePath' parameter for Powershell Windows and Powershell Core." {
    It "New-ModuleSavePath with '<Modules>' / '<PrereleaseModules>'." -Skip:($isWindows -eq $false) -TestCases $ModulePathPSCoreAndWindows {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable,
        [switch]$AllowPrerelease
      )
      {
        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ModulesCache = Get-ModuleCache $ActionParameters
        $Paths = @(New-ModuleSavePath $ModulesCache)
        $ModulesFound = @($ModulesCache.ModuleCacheInformations.Name | Sort-Object)

        switch ($ModulesFound.Count) {
          1 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $ModulesFound[0]))) | Should -Be $true
          }
          2 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[1]))) | Should -Be $true
            $Paths[3] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $ModulesFound[1]))) | Should -Be $true

          }
          3 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $ModulesFound[0]))) | Should -Be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[1]))) | Should -Be $true
            $Paths[3] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $ModulesFound[1]))) | Should -Be $true
            $Paths[4] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $ModulesFound[2]))) | Should -Be $true
            $Paths[5] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $ModulesFound[2]))) | Should -Be $true
          }
          default { $Paths.Count | Should -Be -1 }
        }
      } | Should -Not -Throw
    }
  }
}