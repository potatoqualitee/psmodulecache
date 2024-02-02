#SaveModuleCache.Tests.ps1
#Records the information of the requested modules (step 1) then saves them (step 2).
Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

#Skip :  $ModulesCache.ModuleSavePaths references the paths of the local workstation. 'We don't mix up apples and pears'.
Describe 'Github Action "psmodulecache" module. When there is no error.' -Skip:( (Test-Path env:CI) -eq $false) -Tag 'SaveModuleCache' {
    Context "Save requested modules." {
        It "Records the information of the requested modules (step 1) then saves them (step 2)." {
            $params = @{
                Modules           = 'InvokeBuild:5.10.4,PSModuleCache\Duplicate,Az:9.3.0';
                PrereleaseModules = 'OnlyPrereleaseVersion::';
                Shells            = 'powershell,pwsh';
                Updatable         = $true
            }
            $ActionParameters = New-ModuleCacheParameter @params
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
            $null = $ModulesCache | Export-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)
            #Note : To test on a local workstation, the $ModulesCache.ModuleSavePaths variable must use the path contained in the $CacheFileName variable ( $path+'ShellName')

            Save-ModuleCache
            Remove-Item -Path (Join-Path $home -ChildPath $CacheFileName)

            #GitHub Actions Runner Images contains the 'AZ' module but the version may be different depending on the OS
            $M = Import-Module AZ -PassThru -RequiredVersion 9.3.0
            $M.RepositorySourceLocation.AbsoluteUri | Should -Be 'https://www.powershellgallery.com/api/v2'

            $M = Import-Module InvokeBuild -PassThru
            $M.Version | Should -Be '5.10.4'
            $M.RepositorySourceLocation.AbsoluteUri | Should -Be 'https://www.powershellgallery.com/api/v2'

            $M = Import-Module Duplicate -PassThru
            #Dependencies are implicitly tested
            $M.Version | Should -Be '1.0.0'
            $M.RepositorySourceLocation.AbsoluteUri | Should -Be 'https://nuget.cloudsmith.io/psmodulecache/test/v2/'

            $M = Import-Module OnlyPrereleaseVersion -PassThru
            $M.Version | Should -Be '1.0.0'
            $M.PrivateData.PSData.Prerelease | Should -Be 'beta'
            $M.RepositorySourceLocation.AbsoluteUri | Should -Be 'https://nuget.cloudsmith.io/psmodulecache/test/v2/'
        }

        It "We make sure to save the latest prerelease version in case of request for two versions." {
            $params = @{
                PrereleaseModules = 'psmodulecache\string:1.1.0-beta,psmodulecache\string:1.1.0-alpha'
                #!!PrereleaseModules = 'psmodulecache\string:1.1.0-beta,psmodulecache\string::'
                #!!If the latest version is 1.1.0, the 'beta' version will be saved.

                Shells            = 'powershell,pwsh';
                Updatable         = $false
            }
            $ActionParameters = New-ModuleCacheParameter @params
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
            $null = $ModulesCache | Export-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)

            Save-ModuleCache
            Remove-Item -Path (Join-Path $home -ChildPath $CacheFileName)

            $M = Import-Module String -PassThru
            $M.Version | Should -Be '1.1.0'
            $M.PrivateData.PSData.Prerelease | Should -Be 'beta'
            $M.RepositorySourceLocation.AbsoluteUri | Should -Be 'https://nuget.cloudsmith.io/psmodulecache/test/v2/'
        }

        It "We accept all required license automatically (psmodulecache)." {
            $params = @{
                Modules   = 'PSModuleCache\modulerequirelicenseacceptance:2.0'
                Shells    = 'powershell,pwsh';
                Updatable = $false
            }
            $ActionParameters = New-ModuleCacheParameter @params
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
            $null = $ModulesCache | Export-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)

            Save-ModuleCache
            Remove-Item -Path (Join-Path $home -ChildPath $CacheFileName)

            $M = Import-Module modulerequirelicenseacceptance -PassThru
            $M.Version | Should -Be '2.0'
            $M.PrivateData.PSData.RequireLicenseAcceptance | Should -Be $true
        }

        It "We accept all required license automatically (psgallery)." -Skip:($PSVersionTable.PSEdition -eq 'Core') {
            $params = @{
                Modules   = 'SqlChangeAutomation'
                Shells    = 'powershell';
                Updatable = $false
            }
            $ActionParameters = New-ModuleCacheParameter @params
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
            $null = $ModulesCache | Export-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)

            Save-ModuleCache
            Remove-Item -Path (Join-Path $home -ChildPath $CacheFileName)

            $M = Import-Module SqlChangeAutomation -PassThru
            $M.PrivateData.PSData.RequireLicenseAcceptance | Should -Be $true
        }

        It "All license required by dependencies are accepted automatically." {
            $params = @{
                Modules   = 'PSModuleCache\DependencyRequiresAcceptanceOfTheLicense'
                Shells    = 'powershell,pwsh';
                Updatable = $false
            }
            $ActionParameters = New-ModuleCacheParameter @params
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations | Should -Not -Be $null
            $null = $ModulesCache | Export-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)

            Save-ModuleCache
            Remove-Item -Path (Join-Path $home -ChildPath $CacheFileName)

            Import-Module modulerequirelicenseacceptance
            $M = Import-Module DependencyRequiresAcceptanceOfTheLicense -PassThru
            $M.Version | Should -Be '1.0.0'
        }
    }
}






