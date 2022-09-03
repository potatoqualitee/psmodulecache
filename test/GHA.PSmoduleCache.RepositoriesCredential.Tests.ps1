#GHA.PSmoduleCache.RepositoriesCredential.Tests.ps1
# Check if a serialized object matches the expected structure

$global:PSModuleCacheResources=Import-PowerShellDataFile "$PSScriptRoot/../PSModuleCache.Resources.psd1" -EA Stop
Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Test-RepositoriesCredential function. When there is no error.' -Tag 'HashtableValidation' {

  Context "Valid hashtable object" {
    it "Only one entry" -Skip:((Test-Path Env:CLOUDSMITHPASSWORD) -eq $false) {
      $Credential=New-Object PSCredential($Env:CLOUDSMITHACCOUNTNAME,$(ConvertTo-SecureString $Env:CLOUDSMITHPASSWORD -AsPlainText -Force) )
      $RepositoriesCredential=@{}
      $RepositoriesCredential.'PSGallery'=$Credential

      InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
         $script:FunctionnalErrors.Clear()
         Test-RepositoriesCredential -InputObject $Datas| Should -be $true
      }
    }

    it "Two entries" -Skip:((Test-Path Env:CLOUDSMITHPASSWORD) -eq $false) {
      $Credential=New-Object PSCredential($Env:CLOUDSMITHACCOUNTNAME,$(ConvertTo-SecureString $Env:CLOUDSMITHPASSWORD -AsPlainText -Force) )
      $RepositoriesCredential=@{}
      $RepositoriesCredential.'PSGallery'=$Credential
      $RepositoriesCredential.'OttoMatt'=$Credential

      InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
         $script:FunctionnalErrors.Clear()
         Test-RepositoriesCredential -InputObject $Datas| Should -be $true
      }
    }

    it "Find-Module with credential" -Skip:((Test-Path Env:CI) -eq $false) {
      $Path=Join-Path $home -ChildPath $Env:PSModuleCacheCredentialFileName
      $RepositoriesCredential=Import-CliXml -Path $Path

      $Credential=$RepositoriesCredential.$Env:CloudsmithRepositoryName
      Find-Module -Name Etsdatetime -Repository $Env:CloudsmithRepositoryName -allowprerelease -Credential $credential|Should -Not -Be $Null
    }
  }
}

Describe 'Test-RepositoriesCredential function. When there error.' -Tag 'HashtableValidation' {

   Context "Invalid credential hashtable." {
      it "Invalid serialized object : ValidationMustBeHashtable" {
         $RepositoriesCredential=@(1..2)

         InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
            $script:FunctionnalErrors.Clear()
            Test-RepositoriesCredential -InputObject $Datas| Should -be $false
            $script:FunctionnalErrors.Count| Should -be 1
            $script:FunctionnalErrors[0] |Should -be $global:PSModuleCacheResources.ValidationMustBeHashtable
         }
      }

      it "Invalid serialized object : ValidationMustContainAtLeastOneEntry" {
         $RepositoriesCredential=@{}

         InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
            $script:FunctionnalErrors.Clear()
            Test-RepositoriesCredential -InputObject $Datas| Should -be $false
            $script:FunctionnalErrors.Count| Should -be 1
            $script:FunctionnalErrors[0] |Should -be $global:PSModuleCacheResources.ValidationMustContainAtLeastOneEntry
         }
      }

      it "Invalid serialized object : ValidationWrongItemType" {
         $Credential=New-Object PSCredential('Test',$(ConvertTo-SecureString 'Test' -AsPlainText -Force) )
         $RepositoriesCredential=@{}
         $RepositoriesCredential.'PSGallery'=$Credential
         $RepositoriesCredential.'MyGet'=@(1..2)

         InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
            $script:FunctionnalErrors.Clear()
            Test-RepositoriesCredential -InputObject $Datas| Should -be $false
            $script:FunctionnalErrors.Count| Should -be 1
            $script:FunctionnalErrors[0] |Should -be $global:PSModuleCacheResources.ValidationWrongItemType
         }
      }

      it "Invalid serialized object : ValidationInvalidKey" {
         $Credential=New-Object PSCredential('Test',$(ConvertTo-SecureString 'Test' -AsPlainText -Force) )
         $RepositoriesCredential=@{}
         $RepositoriesCredential.''=$Credential

         InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
            $script:FunctionnalErrors.Clear()
            Test-RepositoriesCredential -InputObject $Datas| Should -be $false
            $script:FunctionnalErrors.Count| Should -be 1
            $script:FunctionnalErrors[0] |Should -be $global:PSModuleCacheResources.ValidationInvalidKey
         }
      }

      it "Invalid serialized object : ValidationUnknownRepository" {
         $Credential=New-Object PSCredential('Test',$(ConvertTo-SecureString 'Test' -AsPlainText -Force) )
         $RepositoriesCredential=@{}
         $RepositoriesCredential.'PSGallery'=$Credential
         $RepositoriesCredential.'UnknownRepository'=$Credential

         InModuleScope 'PsModuleCache' -Parameters @{ Datas=$RepositoriesCredential} {
            $script:FunctionnalErrors.Clear()
            Test-RepositoriesCredential -InputObject $Datas| Should -be $false
            $script:FunctionnalErrors.Count| Should -be 1
            $script:FunctionnalErrors[0] |Should -be $global:PSModuleCacheResources.ValidationUnknownRepository
         }
      }
   }
}
