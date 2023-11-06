#ModuleNameRepositoryQualified.Tests.ps1
#Checks the the syntax 'Repository-Qualified module name'.

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

# !! For 'PSGallery\Pester:5.0.0' the 'Get-RepositoryQualifiedModuleName' function gets only 'PSGallery\Pester',
# !! the version number is removed before it is called

$global:InvalidRQMN = @(
  # This case is tested before calling the function 'Get-RepositoryQualifiedModuleName'.
  # @{RQMN_String = '' }

  @{RQMN_String = '\\' },

  @{RQMN_String = '\RepositoryName\ModuleName' },
  @{RQMN_String = 'RepositoryName\ModuleName\' },
  @{RQMN_String = '\RepositoryName\ModuleName\' },
  @{RQMN_String = 'RepositoryName\\ModuleName' }
)

$global:InvalidRepositoryPart = @(
  # This case is tested before calling the function 'Get-RepositoryQualifiedModuleName'.
  #@{RQMN_String = ' ' }

  @{RQMN_String = '\' }
  @{RQMN_String = ' \' },
  @{RQMN_String = '\ ' },
  @{RQMN_String = ' \ ' },
  @{RQMN_String = ' \ModuleName' },
  @{RQMN_String = '\ModuleName' }
)

$global:RepositoryNotExist = @(
  #The repository name does not exist
  @{RQMN_String = 'NotExist\Pester' },

  #The repository name exist but contains one or more space characters
  @{RQMN_String = ' PSGallery\Pester' },
  @{RQMN_String = 'PSGallery \Pester' },
  @{RQMN_String = ' PSGallery \Pester' }
)

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'PrefixIdentifier' {

  Context "Correct syntax for a module name 'repository qualified'." {
    It 'A module name can be alone (without a repository name).' {
      InModuleScope 'PsModuleCache' {
        $ModuleName = 'Pester'
        $RQMN = Get-RepositoryQualifiedModuleName -ModuleName $ModuleName
        $RQMN | Should -Not -Be $null
        $RQMN.RepositoryName | Should -Be $null
        ($RQMN.ModuleName -eq $ModuleName) | Should -Be $true
      }
    }

    It 'A module name can be associated with a repository name.' {
      InModuleScope 'PsModuleCache' {
        $RepositoryName = 'PSGallery'
        $ModuleName = 'Pester'
        $RQMN_String = "$RepositoryName\$ModuleName"

        $RQMN = Get-RepositoryQualifiedModuleName -ModuleName $RQMN_String
        $RQMN | Should -Not -Be $null
        ($RQMN.RepositoryName -eq $RepositoryName) | Should -Be $true
        ($RQMN.ModuleName -eq $ModuleName) | Should -Be $true
      }
    }
  }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'PrefixIdentifier' {
  Context "Wrong syntax for a module name 'repository qualified'." {

    It "There must be only one '\' in the string. RQMN_String='<RQMN_String>'" -TestCases $global:InvalidRQMN {
      param( $RQMN_String )
      InModuleScope 'PsModuleCache' -Parameters @{ ModuleName = $RQMN_String } {
        $script:FunctionnalErrors.Clear()
        Get-RepositoryQualifiedModuleName -ModuleName $ModuleName
        $ErrorMessage = $PSModuleCacheResources.RQMN_InvalidSyntax -f $ModuleName
        ($script:FunctionnalErrors[0] -eq $ErrorMessage) | Should -Be $true
      }
    }

    It 'The name of a repository cannot be empty.' -TestCases $global:InvalidRepositoryPart {
      param( $RQMN_String )
      InModuleScope 'PsModuleCache' -Parameters @{ ModuleName = $RQMN_String } {
        $script:FunctionnalErrors.Clear()
        Get-RepositoryQualifiedModuleName -ModuleName $ModuleName
        $ErrorMessage = $PSModuleCacheResources.RQMN_RepositoryPartInvalid
        ($script:FunctionnalErrors[0] -eq $ErrorMessage) | Should -Be $true
      }
    }

    It 'The repository must exist.' -TestCases $global:RepositoryNotExist {
      param( $RQMN_String )

      InModuleScope 'PsModuleCache' -Parameters @{ ModuleName = $RQMN_String } {
        $script:FunctionnalErrors.Clear()
        Get-RepositoryQualifiedModuleName -ModuleName $ModuleName
        $Names = $ModuleName.Split('\')
        $ErrorMessage = $PSModuleCacheResources.RQMN_RepositoryNotExist -f $Names[0]
        ($script:FunctionnalErrors[0] -eq $ErrorMessage) | Should -Be $true
      }
    }

  }
}
