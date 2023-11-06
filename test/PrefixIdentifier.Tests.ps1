#PrefixIdentifier.Tests.ps1
#Checks the 'PrefixIdentifier' parameter of the Action and the possible syntax errors.

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'PrefixIdentifier' {

  Context "Syntax for the 'PrefixIdentifier' parameter." {
    It '"PrefixIdentifier" parameter equal to $true' {
      $parameters = @{Modules = 'PSScriptAnalyzer'; Shells = 'powershell'; Updatable = $false; PrefixIdentifier = $true }

      $ActionParameters = New-ModuleCacheParameter @parameters
      $ModulesCache = Get-ModuleCache $ActionParameters
      $ModulesCache.Key | Should -Match "^$env:GITHUB_WORKFLOW-"
    }

    It '"PrefixIdentifier" parameter equal to $false' {
      $parameters = @{Modules = 'PSScriptAnalyzer'; Shells = 'powershell'; Updatable = $false; PrefixIdentifier = $false }

      $ActionParameters = New-ModuleCacheParameter @parameters
      $ModulesCache = Get-ModuleCache $ActionParameters
      $ModulesCache.Key | Should -Not -Match "^$env:GITHUB_WORKFLOW-"
    }
  }
}
