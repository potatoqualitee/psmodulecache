# Changelog

## Release Notes

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