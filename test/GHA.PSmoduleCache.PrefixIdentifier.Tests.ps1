#GHA.PSmoduleCache.PrefixIdentifier.Tests.ps1
#Checks the 'PrefixIdentifier' parameter of the Action and the possible syntax errors.

$global:PSModuleCacheResources=Import-PowerShellDataFile "$PSScriptRoot/../PSModuleCache.Resources.psd1" -EA Stop
Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force


Describe 'Action parameter "PrefixIndentifier". When there is no error.' -Tag 'PrefixIdentifier' {

  Context "Syntax for the 'PrefixIdentifier' parameter." {
    it '"PrefixIdentifier" parameter equal to $true'{
        $parameters=@{Modules='PSScriptAnalyzer'; Shells='powershell';Updatable=$false;PrefixIdentifier=$true}

        $ActionParameters=New-ModuleCacheParameter @parameters
        $ModulesCache=Get-ModuleCache $ActionParameters
        $ModulesCache.Key | should -match "^$env:GITHUB_WORKFLOW-"
    }

    it '"PrefixIdentifier" parameter equal to $false' {
      $parameters=@{Modules='PSScriptAnalyzer'; Shells='powershell';Updatable=$false;PrefixIdentifier=$false}

      $ActionParameters=New-ModuleCacheParameter @parameters
      $ModulesCache=Get-ModuleCache $ActionParameters
      $ModulesCache.Key | should -not -match "^$env:GITHUB_WORKFLOW-"
    }
  }
}
