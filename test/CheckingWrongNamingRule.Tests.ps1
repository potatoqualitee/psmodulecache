#CheckingWrongNamingRule.Tests.ps1
# We only test one 'defective' module, the case without error is tested implicitly by the other tests.

$ModuleInvalidatingTheRule = @(
    #The following test case will always fail :  Find-Package: No match was found for the specified search criteria...
    @{Modules = 'PsGallery\AzureRM.profile:5.8.3'; Shells = 'pwsh'; Updatable = $false }
    # @{Modules = 'PsGallery\psnotification:0.5.3'; Shells = 'pwsh'; Updatable = $false }
    # @{Modules = 'PsGallery\PSColor:1.0.0.0'; Shells = 'pwsh'; Updatable = $false }
    # @{Modules = 'PsGalleryfifa2018:0.2.45'; Shells = 'pwsh'; Updatable = $false }

    @{PrereleaseModules = 'PsGallery\AzureRM.profile'; Shells = 'pwsh'; Updatable = $false }
    # @{PrereleaseModules = 'PsGallery\psnotification'; Shells = 'pwsh'; Updatable = $false }
    # @{PrereleaseModules = 'PsGallery\PSColor'; Shells = 'pwsh'; Updatable = $false }
    # @{PrereleaseModules = 'PsGallery\fifa2018'; Shells = 'pwsh'; Updatable = $false }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

#We run this test in all environments (but only into Github action), the objective is to warn of a potential problem due to the construction of the package.
Describe 'Github Action "psmodulecache" module. When there is no error.' -Skip:( (Test-Path env:CI) -eq $false) -Tag 'NamingWithUbuntu' {

    Context "The PSD1 or PSM1 files must have the same name (case sensitive) as the folder name." {
        It "Valide the rule with the module '<Modules> / '<PrereleaseModules>'. This module can not be imported under Ubuntu." -TestCases $ModuleInvalidatingTheRule {
            param(
                $Modules,
                $PrereleaseModules,
                $Shells,
                [switch]$Updatable
            )
            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
            $null = $ModulesCache | Export-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)
            #Note : To test on a local workstation, the $ModulesCache.ModuleSavePaths variable must use the path contained in the $CacheFileName variable ( $path+'ShellName')

            Save-ModuleCache
            Remove-Item -Path (Join-Path $home -ChildPath $CacheFileName)

            #Confirm-NamingModuleCacheInformation does not generate any errors only a warning in case of content deemed defective for Ubuntu.
            InModuleScope 'PsModuleCache'  -Parameters @{ MCI = $ModulesCache.ModuleCacheInformations; MSP = $ModulesCache.ModuleSavePaths } {
                Confirm-NamingModuleCacheInformation -ModuleCacheInformation $MCI -ModuleSavePath $MSP | Should -Be $false
            }
        }
    }
}