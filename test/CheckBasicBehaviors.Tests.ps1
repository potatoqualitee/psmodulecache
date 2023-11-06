
#CheckBasicBehaviors.Tests.ps1
#Check basic features.

$global:ModuleNameAndVersionExist = @(
    #Avoid duplication of the string module by specifying a version that only exists in the PsModulecache repository
    #In this case the 'RQMN' syntax is not necessary
    @{UseCase = 'Request prerelease version'; PrereleaseModules = 'String:1.1.0-alpha'; Shells = 'powershell,pwsh'; Updatable = $false }
    @{UseCase = 'Request stable version'; Modules = 'String:3.0.0'; Shells = 'powershell,pwsh'; Updatable = $false }
    @{UseCase = 'Request stable version'; Modules = 'String:0.6.1'; Shells = 'powershell,pwsh'; Updatable = $false }

)

$global:ModuleNameNotExist = @(
    #The following test case will always fail :  Find-Package: No match was found for the specified search criteria...
    #The module do not exist
    @{UseCase = 'Request stable version'; Modules = 'NotExist'; Shells = 'powershell,pwsh'; Updatable = $false }
    @{UseCase = 'Request prerelease version'; PrereleaseModules = 'NotExist'; Shells = 'powershell,pwsh'; Updatable = $false }

    @{UseCase = 'Request updatable stable version'; Modules = 'NotExist::'; Shells = 'powershell,pwsh'; Updatable = $True }
    @{UseCase = 'Request updatable prerelease version'; PrereleaseModules = 'NotExist::'; Shells = 'powershell,pwsh'; Updatable = $True }
)

$global:ModuleVersionNotExist = @(
    #The module exist but not the stable version requested
    @{UseCase = 'Request stable version'; Modules = 'Microsoft.Powershell.SecretManagement:100.50.10'; Shells = 'powershell,pwsh'; Updatable = $false }

    #The module exist but not the prerelease version requested
    @{UseCase = 'Request prerelease version'; PrereleaseModules = 'Microsoft.Powershell.SecretManagement:100.50.9-preview1'; Shells = 'powershell'; Updatable = $false }
)

#by Name
$global:ModuleExistsInSeveralRepositories = @(
    #Duplication by name, String and Main exist in PSGallery and PSmodulecache repositories
    @{Modules = 'Main'; Shells = 'powershell'; Updatable = $false }
    @{PrereleaseModules = 'Main::'; Shells = 'pwsh'; Updatable = $true }

    @{Modules = 'String'; Shells = 'pwsh'; Updatable = $false }
    @{Modules = 'String::'; Shells = 'powershell'; Updatable = $true }

    @{PrereleaseModules = 'String'; Shells = 'powershell,pwsh'; Updatable = $false }
    @{PrereleaseModules = 'String::'; Shells = 'powershell,pwsh'; Updatable = $true }

    #Duplication by name and version, String v1.1.3 exist in PSGallery and PsMmodulecache repositories
    @{Modules = 'String:1.1.3'; Shells = 'powershell,pwsh'; Updatable = $false }
)

$global:ModuleDependenciesExistsInSeveralRepositories = @(
    @{Modules = 'Duplicate'; Shells = 'pwsh'; Updatable = $false }
    @{PrereleaseModules = 'Duplicate::'; Shells = 'pwsh'; Updatable = $true }
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

BeforeAll {
    $LastStableVersion = @{
        'SecretManagement' = (Find-Module 'Microsoft.PowerShell.SecretManagement' -Repository 'PSGallery').Version
        'String'           = (Find-Module 'String' -Repository 'PSModuleCache').Version
    }
    $LastStableVersion > $null #Fix PSSSA rule

    $LastestVersion = (Find-Module 'Microsoft.PowerShell.SecretManagement' -AllowPrerelease -Repository 'PSGallery').Version
    $LastestVersion > $null

    $LastPrereleaseVersions = @(Find-Module 'Microsoft.PowerShell.SecretManagement' -Repository 'PSGallery' -AllVersions -AllowPrerelease )
    $LastPrereleaseVersion = $LastPrereleaseVersions[0].Version
    $LastPrereleaseVersion  > $null
}

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'BasicFeatures' {
    Context 'Retrieve the requested version' {
        It "Get the 'SecretManagement' module from the 'PSGallery' repository with the stable version '1.1.0'" {
            $Modules = 'Microsoft.Powershell.SecretManagement:1.1.0'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            #The key construction depends on the OS and version of the GHA Runner: Linux-6.0, Windows- ...
            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-Microsoft\.PowerShell\.SecretManagement:1.1.0'

            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '1.1.0'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $False
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }

        It "Get the 'SecretManagement' module from the 'PSGallery' repository and with the prerelease version '1.1.0-preview'" {
            # !!! The indicated module must have a prerelease published on PSGallery
            $PrereleaseModules = 'Microsoft.Powershell.SecretManagement:1.1.0-preview'
            $Shells = 'powershell'

            $ActionParameters = New-ModuleCacheParameter -PrereleaseModules $PrereleaseModules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-Microsoft\.PowerShell\.SecretManagement:1.1.0-preview'
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '1.1.0-preview'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $True
        }

        It "Get the latest stable version of the 'SecretManagement' module from the 'PSGallery' repository" {
            #In this case the version is missing in the key name
            $Modules = 'Microsoft.Powershell.SecretManagement'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-Microsoft\.PowerShell\.SecretManagement'
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be $LastStableVersion.'SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $False
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }

        It "Get the latest prerelease version (or the latest stable version) of the 'SecretManagement' module from the 'PSGallery' repository" {
            $PrereleaseModules = 'Microsoft.Powershell.SecretManagement'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -PrereleaseModules $PrereleaseModules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-Microsoft\.PowerShell\.SecretManagement'
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be $LastPrereleaseVersion
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $True
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }

        It "Trying to get latest prerelease version of the 'OnlyStableVersion' Module from the 'PSModuleCache' repository. The module exist into the repository but only a stable version was published there." {

            $ActionParameters = New-ModuleCacheParameter -PrereleaseModules 'OnlyStableVersion' -Shells 'powershell,pwsh'
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-OnlyStableVersion'
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'OnlyStableVersion'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSModuleCache'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '1.0.0'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $true
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }

        It "Trying to get latest prerelease version of the ''LatestStableVersion' Module from the 'PSModuleCache' repository. The last version published is a stable version, this is what is returned." {

            $ActionParameters = New-ModuleCacheParameter -PrereleaseModules 'LatestStableVersion' -Shells 'powershell,pwsh'
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-LatestStableVersion'
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'LatestStableVersion'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSModuleCache'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be '2.0.0'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $true
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }
        It "Get latest stable version of the 'SecretManagement' module from the 'PSGallery' repository, then update cache" {
            $Modules = 'Microsoft.Powershell.SecretManagement::'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells -Updatable
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match "^.*?-Updatable-powershell-pwsh-Microsoft\.PowerShell\.SecretManagement:$($LastStableVersion.'SecretManagement')"
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Updatable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be $LastStableVersion.'SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $False
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }

        It "Get the latest prerelease version of the 'SecretManagement' module from the 'PSGallery' repository, then update the cache" {
            $PrereleaseModules = 'Microsoft.Powershell.SecretManagement::'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match "^.*?-Updatable-powershell-pwsh-Microsoft\.PowerShell\.SecretManagement:$LastPrereleaseVersion"
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Updatable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be $LastPrereleaseVersion
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $True
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $false
        }

        It "Get the latest stable version of the 'SecretManagement' module from the 'PSGallery' repository using the 'Repository Qualified Module Name' syntax." {
            $Modules = 'PSGallery\Microsoft.Powershell.SecretManagement'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-PSGallery\\Microsoft\.PowerShell\.SecretManagement'
            # !!! It is assumed that this module has no dependencies
            $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'Microsoft\.PowerShell\.SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'
            $ModulesCache.ModuleCacheInformations[0].Type | Should -Be 'Immutable'
            $ModulesCache.ModuleCacheInformations[0].Version | Should -Be $LastStableVersion.'SecretManagement'
            $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $False
            $ModulesCache.ModuleCacheInformations[0].isRepositoryQualifiedModuleName | Should -Be $true
        }

        It "We use the 'Repository Qualified Module Name' syntax to avoid duplicate module error ('PSModuleCache\String')." {
            $Modules = 'PSModuleCache\String'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-PSModuleCache\\String'

            $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'String' }
            $MainModule.Name | Should -MatchExactly 'String'
            $MainModule.Repository | Should -Be 'PSModuleCache'
            $MainModule.Type | Should -Be 'Immutable'
            $MainModule.Version | Should -Be $LastStableVersion.'String'
            $MainModule.AllowPrerelease | Should -Be $False
            $MainModule.isRepositoryQualifiedModuleName | Should -Be $true
        }

        It "We use the 'Repository Qualified Module Name' syntax to avoid duplicate dependencies error ('PSModuleCache\Duplicate')." {
            $Modules = 'PSModuleCache\Duplicate'
            $Shells = 'powershell,pwsh'

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -Shells $Shells
            $ModulesCache = Get-ModuleCache $ActionParameters
            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1

            $ModulesCache.Key | Should -Match '^.*?-Immutable-powershell-pwsh-PSModuleCache\\Duplicate'
            $MainModule = $ModulesCache.ModuleCacheInformations | Where-Object { $_.Name -eq 'Duplicate' }
            $MainModule.Name | Should -MatchExactly 'Duplicate'
            $MainModule.Repository | Should -Be 'PSModuleCache'
            $MainModule.Type | Should -Be 'Immutable'
            $MainModule.Version | Should -Be '1.0.0'
            $MainModule.AllowPrerelease | Should -Be $False
            $MainModule.isRepositoryQualifiedModuleName | Should -Be $true
        }

        It 'The module name and version exists in a single repository : <UseCase>' -TestCases $global:ModuleNameAndVersionExist {
            param(
                $UseCase,
                $Modules,
                $PrereleaseModules,
                $Shells,
                [switch]$Updatable
            )

            $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
            $ModulesCache = Get-ModuleCache $ActionParameters

            $ModulesCache.ModuleCacheInformations.Count | Should -Be 1
            switch ($ModulesCache.ModuleCacheInformations[0].Version) {
                '1.1.0-alpha' {
                    $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSModuleCache'; break
                    $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $true
                    $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'String'
                }
                '0.6.1' {
                    $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSGallery'; break
                    $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $false
                    $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'string'
                }
                '3.0.0' {
                    $ModulesCache.ModuleCacheInformations[0].Repository | Should -Be 'PSModuleCache'; break
                    $ModulesCache.ModuleCacheInformations[0].AllowPrerelease | Should -Be $false
                    $ModulesCache.ModuleCacheInformations[0].Name | Should -MatchExactly 'String'
                }
                default { throw "Assert: CheckBasicBehaviors.Tests.ps1 unknown value for the 'Version' property." }
            }
        }
    }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'BasicFeatures' {

    It 'The module name do not exist: <UseCase>' -TestCases $global:ModuleNameNotExist {
        param(
            $UseCase,
            $Modules,
            $PrereleaseModules,
            $Shells,
            [switch]$Updatable
        )

        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester

        $ErrorModulesCache.Count | Should -Be 1
        $ErrorModulesCache[0] | Should -Match "^Find-Package: No match was found for the specified search criteria"
    }

    It 'The module version do not exist: <UseCase>' -TestCases $global:ModuleVersionNotExist {
        param(
            $UseCase,
            $Modules,
            $PrereleaseModules,
            $Shells,
            [switch]$Updatable
        )

        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
        $ErrorModulesCache.Count | Should -Be 1
        $ErrorModulesCache[0] | Should -Match "^Find-Package: No match was found for the specified search criteria"
    }

    It "'Get latest stable version of the 'OnlyPrereleaseVersion' module from the 'PsModulecache' repository. The module exist into the repository but only a prerelease version was published there" {

        $ActionParameters = New-ModuleCacheParameter -Modules 'OnlyPrereleaseVersion' -Shells 'powershell,pwsh'
        $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester
        $ErrorModulesCache.Count | Should -Be 1
        $ErrorModulesCache[0] | Should -Match "^Find-Package: No match was found for the specified search criteria"
    }

    It "The module exists in several repositories : '[<Modules> (stable)] / [<PrereleaseModules> (prerelease)]. Updatable:<Updatable>'"  -TestCases $global:ModuleExistsInSeveralRepositories {
        param(
            $Modules,
            $PrereleaseModules,
            $Shells,
            [switch]$Updatable
        )

        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester

        $ErrorModulesCache.Count | Should -Be 1
        $ErrorModulesCache[0] | Should -Match "The module '.*?' exists in several repositories"
    }

    It "Searching for module dependencies returns wrong result from several repositories : '[<Modules> (stable)] / [<PrereleaseModules> (prerelease)]. Updatable:<Updatable>'" -Skip:($PSVersionTable.PSEdition -eq 'Core') -TestCases $global:ModuleDependenciesExistsInSeveralRepositories {
        #The use case with 'Duplicate' module do not works on Unbuntu or MacOs (pwsh.exe), the behavior is erratic in the Github Action or WSL.
        #The result is either right or wrong
        param(
            $Modules,
            $PrereleaseModules,
            $Shells,
            [switch]$Updatable
        )

        $ActionParameters = New-ModuleCacheParameter -Modules $Modules -PrereleaseModules $PrereleaseModules -Shells $Shells -Updatable:$Updatable
        $ErrorModulesCache = Get-ModuleCache $ActionParameters -Pester

        #Always true under Windows.
        $ErrorModulesCache.Count | Should -Be 1
        $ErrorModulesCache[0] | Should -Match "Searching for module '.*?' dependencies returns wrong result from several repositories"
    }
}