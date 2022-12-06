#GHA.PSmoduleCache.PowershellGetVersion.Tests.ps1
# Checks the syntax for a PowershellGet version.

# See :  https://learn.microsoft.com/en-us/powershell/scripting/gallery/concepts/module-prerelease-support?view=powershell-5.1


[String[]]$global:ValidPowershellGetVersionsWithoutPrerelease = @(
   # [Version]
   '0.0.0.0'
   '0.0.0',
   '1.2',
   '01.1.1',
   '1.01.1',
   '1.1.01',
   '1.2.3',
   '2022.1.2.3',
   '1.0',
   '0.0.4',
   '10.20.30',
   '1.0.0',
   '2.0.0',
   '1.1.7'
   #The following version numbers are valid but do not follow the standard defined for PowershellGet.
   #Their use does not trigger a syntax error but returns 'NoMatchFoundForCriteria'.
   '1.0-',
   '1.2-',
   '1.2--'
   '1.2.3-',
   '1.2.3--',
   '1.2.3.4-',
   '1.2.3.4--'

   #'1.0' is a valid [version] but returns digits initialized to -1
   #  Major  Minor  Build  Revision
   #  -----  -----  -----  --------
   #  1      0      -1     -1
   #note : The value of Version properties that have not been explicitly assigned a value is undefined (-1).

   #[version]'1.0.-1' throw an exception
   #[version]'0.0.-0' OK, return 0.0.0.-1
)

[String[]]$global:ValidPowershellGetVersionsWithPrerelease = @(
   #SemVer v1.0.0
   '0.0.0-0',
   '0.0.0-A',
   '1.2.3-0123',
   '1.0.0-alpha',
   '1.0.0-beta',
   '1.2.3-alpha8',
   '1.0.0-alpha ', #ending spaces are truncated

   #The following version numbers are valid but do not follow the standard defined for PowershellGet.
   #Their use does not trigger a syntax error but returns 'NoMatchFoundForCriteria'.
   '1.2.3--test',
   '1.2.3- Beta1'
)

[String[]]$global:AllValidPowershellGetVersions = $global:ValidPowershellGetVersionsWithoutPrerelease + $global:ValidPowershellGetVersionsWithPrerelease



[String[]]$global:InvalidPowershellGetVersions = @(
   #'-1.2.3-test' bug
   '1.2.3---',
   '0.0.-0',
   '1',
   '11',
   '1.',
   '-1',
   '1.2-Beta',
   #semver 2.0
   '1.2.3-Beta.1',
   '1.2.3-Beta-1',
   '1.2.3-Beta 1',
   '1.2.3.4-1',
   '1.2.3.4-Beta'
   '1.1.2-prerelease+meta',
   '1.1.2+meta',
   '1.1.2+meta-valid',
   '1.0.0-alpha.beta',
   '1.0.0-alpha.beta.1',
   '1.0.0-alpha.1',
   '1.0.0-alpha0.invalid',
   '1.0.0-alpha.0invalid',
   '1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay',
   '1.0.0-rc.1+build.1',
   '2.0.0-rc.1+build.123',
   '10.2.3-DEV-SNAPSHOT',
   '1.2.3-SNAPSHOT-123',
   '2.0.0+build.1848',
   '2.0.1-alpha.1227',
   '1.0.0-alpha+beta',
   '1.2.3----RC-SNAPSHOT.12.9.1--.12+788',
   '1.2.3----R-S.12.9.1--.12+meta',
   '1.2.3----RC-SNAPSHOT.12.9.1--.12',
   '1.0.0+0.build.1-rc.10000aaa-kk-0.1',
   '99999999999999999999999.999999999999999999.99999999999999999',
   #semver with constraint
   '=0.2.3',
   '!=2.0.0+build.1848',
   '<2.0.1-alpha.1227',
   '>1.0.0-alpha+beta',
   '<=1.2.3----RC-SNAPSHOT.12.9.1--.12+788',
   '>=1.2.3----R-S.12.9.1--.12+meta',
   '=<1.2.3----RC-SNAPSHOT.12.9.1--.12',
   '=>1.0.0+0.build.1-rc.10000aaa-kk-0.1',
   '~0.1.2',
   '~>99999999999999999999999.999999999999999999.99999999999999999',
   '^1.0.0-0A.is.legal'

   #InvalidSemanticVersions
   '1.2.3-0123.0123',
   '1.1.2+.123',
   '+invalid',
   '-invalid',
   '-invalid+invalid',
   '-invalid.01',
   'alpha',
   'alpha.beta',
   'alpha.beta.1',
   'alpha.1',
   'alpha+beta',
   'alpha_beta',
   'alpha.',
   'alpha..',
   'beta',
   '1.0.0-alpha_beta',
   '-alpha.',
   '1.0.0-alpha..',
   '1.0.0-alpha..1',
   '1.0.0-alpha...1',
   '1.2.3.DEV',
   '1.2-SNAPSHOT',
   '1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788',
   '1.2-RC-SNAPSHOT',
   '-1.0.3-gamma+b7718',
   '+justmeta',
   '9.8.7+meta+meta',
   '9.8.7-whatever+meta+meta',
   '99999999999999999999999.999999999999999999.99999999999999999----RC-SNAPSHOT.12.09.1--------------------------------..12',
   '2022.1.2.3-beta',
   '1.-1',
   '-1.1'
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'PowershellGetVersion' {

   Context 'Valid version number syntax for PowershellGet.' {
      It 'Test-Version' {

         InModuleScope 'PsModuleCache' -Parameters @{ ValidPSGetVersions = $global:AllValidPowershellGetVersions } {
            $MustBeValidPSGetVersion = [System.Predicate[string]] { param($Version) Test-Version -Version $Version }
            [System.Array]::TrueForAll($ValidPSGetVersions, $MustBeValidPSGetVersion) | Should -Be $True
         }
      }

      It 'Test-PrereleaseVersion version number without Prerelease part.' {

         InModuleScope 'PsModuleCache' -Parameters @{ ValidPSGetVersions = $global:ValidPowershellGetVersionsWithoutPrerelease } {
            $MustBeValidPSGetVersionWithoutPrerelease = [System.Predicate[string]] { param($Version) (Test-PrereleaseVersion -Version $Version) -eq $false }
            [System.Array]::TrueForAll($ValidPSGetVersions, $MustBeValidPSGetVersionWithoutPrerelease) | Should -Be $True
         }
      }

      It 'Test-PrereleaseVersion version number with Prerelease part.' {

         InModuleScope 'PsModuleCache' -Parameters @{ ValidPSGetVersions = $global:ValidPowershellGetVersionsWithPrerelease } {
            $MustBeValidPSGetVersionWithPrerelease = [System.Predicate[string]] { param($Version) Test-PrereleaseVersion -Version $Version }
            [System.Array]::TrueForAll($ValidPSGetVersions, $MustBeValidPSGetVersionWithPrerelease) | Should -Be $True
         }
      }
   }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'PowershellGetVersion' {

   Context 'Invalid version number syntax for PowershellGet' {
      It 'Test-Version' {

         InModuleScope 'PsModuleCache' -Parameters @{ InvalidPSGetVersions = $global:InvalidPowershellGetVersions } {
            $MustBeInvalidPSGetVersion = [System.Predicate[string]] { param($Version) (Test-Version -Version $Version) -eq $false }
            [System.Array]::TrueForAll($InvalidPSGetVersions, $MustBeInvalidPSGetVersion) | Should -Be $True
         }
      }

      It 'Test-PrereleaseVersion.' {

         InModuleScope 'PsModuleCache' -Parameters @{ InvalidPSGetVersions = $global:InvalidPowershellGetVersions } {
            $MustBeInvalidPSGetPrereleaseVersion = [System.Predicate[string]] { param($Version) (Test-PrereleaseVersion -Version $Version) -eq $false }
            [System.Array]::TrueForAll($InvalidPSGetVersions, $MustBeInvalidPSGetPrereleaseVersion) | Should -Be $True
         }
      }
   }
}
