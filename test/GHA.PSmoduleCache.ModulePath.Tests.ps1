#GHA.PSmoduleCache.ModulePath.Tests.ps1
#Checks the construction of the save path names according to the shell and the number of modules.

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
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem::'; Shells = 'powershell'; Updatable = $true }
  @{Modules = 'InvokeBuild::,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'powershell'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'powershell'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'powershell'; Updatable = $false }
)

$ModulePathPSCore = @(
  @{PrereleaseModules = 'InvokeBuild::'; Shells = 'pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild::'; Shells = 'pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild'; Shells = 'pwsh'; Updatable = $false }

  @{PrereleaseModules = 'InvokeBuild::,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild,PnP.PowerShell::'; Shells = 'pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell'; Shells = 'pwsh'; Updatable = $false }

  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell::,DTW.PS.FileSystem'; Shells = 'pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem::'; Shells = 'pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'pwsh'; Updatable = $false }
)

$ModulePathPSCoreAndWindows = @(
  @{PrereleaseModules = 'InvokeBuild::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{PrereleaseModules = 'InvokeBuild::,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild,PnP.PowerShell::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell'; Shells = 'powershell,pwsh'; Updatable = $false }

  @{PrereleaseModules = 'InvokeBuild::,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{Modules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem::'; Shells = 'powershell,pwsh'; Updatable = $true }
  @{PrereleaseModules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $false }
  @{Modules = 'InvokeBuild,PnP.PowerShell,DTW.PS.FileSystem'; Shells = 'powershell,pwsh'; Updatable = $false }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'ModulePath' {

  Context "Syntax for the 'ModulePath' parameter For Windows Powershell." {
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
        $Paths = @(New-ModuleSavePath $ModulesCache.ModuleCacheInformations)
        #module names only
        $Modules = @($ModulesCache.ModuleCacheInformations.Name)

        #note : The result is coupled to the test set.
        switch ($Paths.Count) {
          #Paths may contain a different numeric version, we only test the parent path.
          1 { $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[0]))) | should -be $true }
          2 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[1]))) | should -be $true
          }
          3 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[1]))) | should -be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[2]))) | should -be $true
          }
          default { $Paths.Count | Should -be -1 }
        }
      } | Should -not -Throw
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
        $Paths = @(New-ModuleSavePath $ModulesCache.ModuleCacheInformations)
        $Modules = @($ModulesCache.ModuleCacheInformations.Name)

        switch ($Paths.Count) {
          1 { $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $modules[0]))) | should -be $true }
          2 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $modules[1]))) | should -be $true
          }
          3 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $modules[1]))) | should -be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsLinuxCoreModulePath, $modules[2]))) | should -be $true
          }
          default { $Paths.Count | Should -be -1 }
        }
      } | Should -not -Throw
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
        $Paths = @(New-ModuleSavePath $ModulesCache.ModuleCacheInformations)
        $Modules = @($ModulesCache.ModuleCacheInformations.Name)

        switch ($Paths.Count) {
          2 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $modules[0]))) | should -be $true
          }
          4 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $modules[0]))) | should -be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[1]))) | should -be $true
            $Paths[3] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $modules[1]))) | should -be $true

          }
          6 {
            $Paths[0] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[0]))) | should -be $true
            $Paths[1] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $modules[0]))) | should -be $true
            $Paths[2] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[1]))) | should -be $true
            $Paths[3] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $modules[1]))) | should -be $true
            $Paths[4] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsModulePath, $modules[2]))) | should -be $true
            $Paths[5] -match [regex]::Escape(([System.IO.Path]::Combine($PsWindowsCoreModulePath, $modules[2]))) | should -be $true
          }
          default { $Paths.Count | Should -be -1 }
        }
      } | Should -not -Throw
    }
  }
}