# Changelog

## Release Notes

### v5.3

* Fix (#45). Some module names are case-sensitive, and break the implicit (and informal) PascalCase naming rule.
On Linux, the path names passed as a parameter to the 'Cache' action must be constructed with the nuget package name and not with the name coming from the 'modules-to-cache' parameter of the 'PSModuleCache' action.
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
