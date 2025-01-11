# Changelog

## Release Notes

### v6.2.1
Upgrade to actions/cache v4.2.0. Thanks to David Gardiner (flcdrg)


Additional notes for Ubuntu users :

ubuntu-latest pipelines will use ubuntu-24.04 soon. For more details, see actions/runner-images#10636

See to : https://github.com/actions/runner-images/blob/ubuntu24/20250105.1/images/ubuntu/Ubuntu2404-Readme.md

### v6.2

* Bump actions/cache to v4. Node 16 is deprecated, v4 uses Node 20. Thanks to Frode Flaten (fflaten).

### v6.1

* Fix (#59). Modules requesting acceptance of a license triggered an exception. Now licenses are always accepted.

### v6.0

* Add support for the modules dependencies. Module paths to be saved in cache are unique.
* Refactoring and bug fixes around managing multiple repositories.
* Add module name duplication checking. Previously you could call Save-Module several times for the same module.
* Update actions/cache@v3.0.11 to actions/cache@v3.3.2
* Update actions/checkout@v2.5.0 to actions/checkout@v4.1.0
* Remove unused workflows.

* Fix (#54). Some modules will be impossible to load under Ubuntu, in this case a warning is displayed in the workflow logs.
* Fix (#51). If there is a module with the same name in several PSRepositories, we must now prefix the module name with the name of the desired repository: PSGallery\string.
* Fix (#50). Module dependencies were not saved into a cache. Now each dependency is saved.
* Fix (#47). Documentation: specifies the use of '::' (YAML syntax)
* Fix (#45,#48). Some module packages are case-sensitive, and break the implicit (and informal) PascalCase naming rule.
                 On Linux, the path names passed as a parameter to the 'Cache' action must be constructed with the nuget package name and not with the name coming from the 'modules-to-cache' parameter of the 'PSModuleCache' action.
* Fix the analyze of a module name.
* Fix module name handling for case-sensitive filesystems. See the 'PsModuleCache\Test-ModuleNaming' function.
* Fix module duplication when we call _"Find-Module -name 'AZ' -IncludeDependencies"_. Example: the dependent module 'Az.Accounts v2.13.1' is duplicated 25 times.
* Fix CleanWorkFlowsHistory.yml. Deleting workflow execution history caused an exception when calling ConvertFrom-Json. If the workflow execution history contains a large number of entries (+500) and the API returns a string of several megabytes that is impossible to convert.

## Breaking changes

* Now we check the existence of at least one repository.

* The existence of a module with the same name in several PSRepositories will cause a blocking error.
  We must now prefix a name of the duplicated module with the name of the desired repository.
  Previously we sorted the elements by version number then we selected the first in the list.

### v5.3 (no release)

* Fix (#43). Action fails when used with a container job. The 'SUDO' command may not exist in the container.
* Fix (#38). Updating the setting of output parameters (Github Action).
* Fix (#35). Change after Github Action commands deprecated.
* Update 'Readme.md' file.

### v5.2

* Fix (#40). Now we validate a module version number identical to PowershellGet and not like a Semver 2.0.
* Fix around "Set-PSRepository PSGallery -InstallationPolicy Trusted" when the 'PSGallery' repository is removed.

### v5.1

* Update GITHUB_OUTPUT per GitHub's new requirement (#36)
* Fix line break issue (#39)

### v5.0

* Add support for multiple PSRepositories.
* Add module update for each execution of an Action (`Pester, dbatools::`)
* Add the 'modules-to-cache-prerelease' parameter.
* Add the 'updatable' parameter.
* Add the 'prefixidentifier' parameter.
* Checking the consistency of the values of the 'shell' parameter.
* Syntax check for 'module-to-cache' and 'modules-to-cache-prerelease' parameters.
* The 'main.ps1' script is replaced by a Powershell module (psmodulecache.psm1)
* Add Pester test.
* Rewrite test Actions.
* Add Pester Actions.
* Fixed typecasting of boolean type parameters.
* Fix: Each module directory name to be cached is now passed as a parameter to 'action/cache'.

#### Breaking change

* The 'modules-to-cache' parameter no longer supports prerelease version.
* The 'allow-prerelease' parameter is removed. Now use the parameter 'modules-to-cache-prerelease'.
* The 'force' parameter is removed. Now Save-Module use always -Force.

### v3.5

* Add support for `shell: pwsh, powershell` to install desired modules on both PowerShell and pwsh on Windows

### v3

* Fixes bugs with PowerShell vs pwsh
* Near total rewrite
* Removed uneeded outputs -- write to disk instead

### v2

* Fixed keygen to account for runner os
* Added support for additional parameters for Install-Module
* Added support for RequiredModule (`Pester, dbatools:1.0.0`)
* Added verbosity

### v1.1

* Added support for powershell.exe on Windows
* Fixed KeyGen to fix #7

### v1

* Initial release. Supports PowerShell Gallery with Linux and Windows runners.
