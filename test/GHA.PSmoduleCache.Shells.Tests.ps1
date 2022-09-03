#GHA.PSmoduleCache.Shells.Tests.ps1
#Checks the 'shell' parameter of the Action and the possible syntax errors.

$ShellBasic = @(
  @{PrereleaseModules = ' PSScriptAnalyzer::'; Shells = 'powershell ';Updatable = $true }
  @{PrereleaseModules = 'PSScriptAnalyzer::'; Shells = 'pwsh ';Updatable = $true }
  @{PrereleaseModules = 'PSScriptAnalyzer:: '; Shells = ' powershell,pwsh';Updatable = $true }
  @{Modules = 'PSScriptAnalyzer'; Shells = ' powershell';Updatable = $false }
  @{Modules = 'PSScriptAnalyzer '; Shells = ' pwsh';Updatable = $false }
  @{Modules = ' PSScriptAnalyzer'; Shells = 'powershell,pwsh ';Updatable = $false }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'powershell,pwsh,pwsh,Powershell';Updatable = $False }
)

$ShellEmpty = @(
  @{Modules = 'PSScriptAnalyzer'; Shells = ',';Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = ',,';Updatable = $False }
)

$ShellErrors = @(
  @{Modules = 'PSScriptAnalyzer'; Shells = 'bash';Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; Shells = 'bash,,go';Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; Shells = ',go';Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; Shells = 'go,';Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; Shells = 'powershell,pwsh,go';Updatable = $False }
  @{Modules = 'PSScriptAnalyzer'; Shells = 'pwershell';Updatable = $False }

  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'bash';Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'bash,,go';Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = ',go';Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'go,';Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'powershell,pwsh,go';Updatable = $False }
  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'powrshell';Updatable = $False }

  @{PrereleaseModules = 'PSScriptAnalyzer'; Shells = 'powershell,pwsh,go,,pwsh,Powershell';Updatable = $False }
)

$global:PSModuleCacheResources = Import-PowerShellDataFile "$PSScriptRoot/../PSModuleCache.Resources.psd1" -ErrorAction Stop
Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'Shell' {

  Context "Syntax for the 'shell' parameter." {
    It "Syntax for 'shell' parameter with '<Shells>'." -TestCases $ShellBasic {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      {
        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ModulesCache = Get-ModuleCache $ActionParameters -Pester
        $ModulesCache > $null #bypass PSSA rule
      } | Should -not -Throw
    }
  }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'Shell' {
  Context "Invalid syntax for the 'shell' parameter" {
    It "Invalid syntax 'MustDefineAtLeastOneModule'." {
      $Err = { New-ModuleCacheParameter -Modules 'Test' -Shells '' } | Should -Throw -PassThru
      $Err.Exception.Message | Should -Be $global:PSModuleCacheResources.MustDefineAtLeastOneShell

      $Err = { New-ModuleCacheParameter -PrereleaseModules 'Test' -Updatable } | Should -Throw -PassThru
      $Err.Exception.Message | Should -Be $global:PSModuleCacheResources.MustDefineAtLeastOneShell
    }

    It "Shell return empty array 'MustDefineAtLeastOneModule'." -TestCases $ShellEmpty {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $Err = { New-ModuleCacheParameter -Modules 'Test' -Shells $shells } | Should -Throw -PassThru
      $Err.Exception.Message | Should -Be $global:PSModuleCacheResources.MustDefineAtLeastOneShell
    }

    It "Invalid for '<Shells>'." -TestCases $ShellErrors {
      param(
        $Modules,
        $PrereleaseModules,
        $Shells,
        [switch]$Updatable
      )
      $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
      $ModulesCache = Get-ModuleCache $ActionParameters -Pester
      $ActionParameters.ShellsParameter.IsAuthorizedShells | Should -Be $false
      $ModulesCache.Count | Should -Be 1
      $ModulesCache[0] | Should -match "The 'Shell' parameter contains an empty string or a shell name which is not supported"
    }
  }
}
