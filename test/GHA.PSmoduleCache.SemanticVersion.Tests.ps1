#GHA.PSmoduleCache.SemanticVersion.Tests.ps1
# Checks the syntax for a semantic version (Semver)

[String[]]$global:ValidSemanticVersions = @(
   '0.0.0' #valid CLR version
   '0.0.4', #valid CLR version
   '1.2.3', #valid CLR version
   '10.20.30', #valid CLR version
   '1.0.0', #valid CLR version
   '2.0.0', #valid CLR version
   '1.1.7', #valid CLR version
   '0.0.0-1',
   '1.1.2-prerelease+meta',
   '1.1.2+meta',
   '1.1.2+meta-valid',
   '1.0.0-alpha',
   '1.0.0-beta',
   '1.0.0-alpha.beta',
   '1.0.0-alpha.beta.1',
   '1.0.0-alpha.1',
   '1.0.0-alpha0.valid',
   '1.0.0-alpha.0valid',
   '1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay',
   '1.0.0-rc.1+build.1',
   '2.0.0-rc.1+build.123',
   '1.2.3-beta',
   '10.2.3-DEV-SNAPSHOT',
   '1.2.3-SNAPSHOT-123',
   '2.0.0+build.1848',
   '2.0.1-alpha.1227',
   '1.0.0-alpha+beta',
   '1.2.3----RC-SNAPSHOT.12.9.1--.12+788',
   '1.2.3----R-S.12.9.1--.12+meta',
   '1.2.3----RC-SNAPSHOT.12.9.1--.12',
   '1.0.0+0.build.1-rc.10000aaa-kk-0.1',
   '99999999999999999999999.999999999999999999.99999999999999999'
)

[String[]]$global:ValidSemanticVersionConstraints = @(
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
)

[String[]]$global:InvalidSemanticVersions = @(
   '0.0.0.0' #valid CLR version
   '0.0.-0' #valid CLR version
   '1.2', #valid CLR version
   '01.1.1', #valid CLR version
   '1.01.1', #valid CLR version
   '1.1.01', #valid CLR version
   '1.2', #valid CLR version
   '2022.1.2.3', #valid CLR version
   '1.0', #valid CLR version
   '1',
   '1.',
   '1.2.3-0123',
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
   '1.0.0-alpha....1',
   '1.0.0-alpha.....1',
   '1.0.0-alpha......1',
   '1.0.0-alpha.......1',
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

[String[]]$global:ValidClrVersions = @(
   #'1','11', '1.', '-1' are invalid for [version]'string'

   #'1.0' is valid but returns digits initialized to -1
   #  Major  Minor  Build  Revision
   #  -----  -----  -----  --------
   #  1      0      -1     -1
   #note : The value of Version properties that have not been explicitly assigned a value is undefined (-1).

   #[version]'1.0.-1' throw an exception
   #[version]'0.0.-0'  -> OK !!!
   '0.0.0.0'
   '1.2',
   '1.2.3',
   '2022.1.2.3' #It is a invalid Semver but a valid clr version.
)

Import-Module "$PSScriptRoot/../PSModuleCache.psd1" -Force
$ModuleContext = Get-Module psmodulecache
$global:SemverRegex = &$ModuleContext { $SemverRegex }

Describe 'Github Action "psmodulecache" module. When there is no error.' -Tag 'Semver' {

   Context "valid semantic version." {
      It "Simple version number" {

         $MustBeValidVersion = [System.Predicate[string]] { param($Semver) $Semver -match $global:SemverRegex }
         [System.Array]::TrueForAll($global:ValidSemanticVersions, $MustBeValidVersion) | Should -Be $True
      }

      It "Semantic version constraints" {

         $MustBeValidVersion = [System.Predicate[string]] { param($Semver) $Semver -match $global:SemverRegex }
         [System.Array]::TrueForAll($global:ValidSemanticVersionConstraints, $MustBeValidVersion) | Should -Be $True
      }
   }
}

Describe 'Github Action "psmodulecache" module. When there error.' -Tag 'Semver' {

   Context "invalid semantic version." {
      It "Invalid version number" {

         $MustBeInvalidVersion = [System.Predicate[string]] { param($Semver) $Semver -notmatch $global:SemverRegex }
         [System.Array]::TrueForAll($global:InvalidSemanticVersions, $MustBeInvalidVersion) | Should -Be $True
      }
   }
}

Describe 'Test-PrereleaseVersion' -Tag 'Semver' {
   Context "semantic version, prerelease part." {
      It "Without prerelease part" {
         [String[]]$ValidSemanticVersionsWithoutPrerelease = @(
            '0.0.4',
            '1.2.3',
            '10.20.30',
            '1.1.2+meta',
            '1.1.2+meta-valid',
            '1.0.0',
            '2.0.0',
            '1.1.7',
            '2.0.0+build.1848',
            '1.0.0+0.build.1-rc.10000aaa-kk-0.1',
            '99999999999999999999999.999999999999999999.99999999999999999'
         )

         InModuleScope 'PsModuleCache' -Parameters @{ WithoutPrerelease = $ValidSemanticVersionsWithoutPrerelease } {
            $MustBeInvalidPrerelease = [System.Predicate[string]] { param($Semver) (Test-PrereleaseVersion $global:Semver) -eq $false }
            [System.Array]::TrueForAll($WithoutPrerelease, $MustBeInvalidPrerelease) | Should -Be $True
         }
      }

      It "With prerelease part" {
         [String[]]$ValidSemanticVersionsWithPrerelease = @(
            '1.1.2-prerelease+meta',
            '1.0.0-alpha',
            '1.0.0-beta',
            '1.0.0-alpha.beta',
            '1.0.0-alpha.beta.1',
            '1.0.0-alpha.1',
            '1.0.0-alpha0.valid',
            '1.0.0-alpha.0valid',
            '1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay',
            '1.0.0-rc.1+build.1',
            '2.0.0-rc.1+build.123',
            '1.2.3-beta',
            '10.2.3-DEV-SNAPSHOT',
            '1.2.3-SNAPSHOT-123',
            '2.0.1-alpha.1227',
            '1.0.0-alpha+beta',
            '1.2.3----RC-SNAPSHOT.12.9.1--.12+788',
            '1.2.3----R-S.12.9.1--.12+meta',
            '1.2.3----RC-SNAPSHOT.12.9.1--.12'
         )
         InModuleScope 'PsModuleCache' -Parameters @{ WithPrerelease = $ValidSemanticVersionsWithPrerelease } {
            $MustBeValidPrerelease = [System.Predicate[string]] { param($Semver)  (Test-PrereleaseVersion $Semver) -eq $true }
            [System.Array]::TrueForAll($WithPrerelease, $MustBeValidPrerelease) | Should -Be $True
         }
      }
   }
}