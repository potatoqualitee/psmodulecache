ConvertFrom-StringData @'
    MustDefineAtLeastOneModule                         = You must define at least one module to be cached, either via the 'module-to-cache' parameter or the 'module-to-cache-prerelease' parameter.
    MustDefineAtLeastOneShell                          = You must define at least one shell, 'powershell' or 'pwsh' or both.
    MustBeAnAuthorizedShell                            = The 'Shell' parameter contains an empty string or a shell name which is not supported '{0}'. Allowed shell names are 'pwsh' and 'powershell'.
    EmptyModuleName                                    = A module name is empty for '{0}'.
    InvalidModuleNameSyntax                            = The module name '{0}' contains one or more invalid characters into '{1}'.
    MissingRequiredVersion                             = The required version is not specified for '{0}'.
    InvalidVersionNumberSyntax                         = The syntax of the version '{0}' is invalid for '{1}'.
    ModuleCannotContainPrerelease                      = A module name into 'module-to-cache' cannot contain a prerelease version '{0}'.
    ModuleMustContainPrerelease                        = A module name into 'module-to-cache-prerelease' must contain a prerelease version '{0}'.
    ImmutableCacheCannotContainUpdatableInformation    = An immutable cache cannot contain updatable cache information ('::') into 'module-to-cache' or 'module-to-cache-prerelease' (see '{0}').
    UpdatableCacheMustContainUpdatableInformation      = An updatable cache must contain cache information ('::') into 'module-to-cache' or 'module-to-cache-prerelease' (see '{0}').
    UpdatableModuleCannotContainVersionInformation     = An updatable module must not specify a version number '{0}'.
    StableModuleNamesAreDuplicated                     = The 'modules-to-cache' parameter contains duplicated module names : '{0}'.
    PrereleaseModuleNamesAreDuplicated                 = The 'modules-to-cache-prerelease' parameter contains duplicated module names :'{0}'.
    UnknownModuleName                                  = Find-Package: No match was found for the specified search criteria and the updatable module name '{0}' (repositories '{1}').
    InvalidCharactersInPrereleaseString                = The Prerelease string '{0}' contains invalid characters. Please ensure that only characters 'a-zA-Z0-9' and possibly hyphen ('-') at the beginning are in the Prerelease string.
    InvalidVersion                                     = Cannot convert value '{0}' to type 'System.Version'.
    IncorrectVersionPartsCountForPrereleaseStringUsage = Version '{0}' must have exactly 3 parts for a Prerelease string to be used.
    RegisterAtLeastOneRepository                       = There is no repository, use Register-PSRepository to register at least one.
    ModuleDependenciesExistsInSeveralRepositories      = Searching for module '{0}' dependencies returns wrong result from several repositories. To correct this it is possible to use in the list of module names the syntax 'Repository-Qualified module name': RepositoryName\\ModuleName
    ModuleExistsInSeveralRepositories                  = The module '{0}' exists in several repositories : {1}. To correct this it is possible to use in the list of module names the syntax 'Repository-Qualified module name': RepositoryName\\ModuleName
    RQMN_InvalidSyntax                                 = Repository qualified module name : the string '{0}' does not respect 'RepositoryName\\ModuleName' syntax.
    RQMN_RepositoryPartInvalid                         = Repository qualified module name : the 'repository name' part cannot be an empty string.
    RQMN_RepositoryNotExist                            = Repository qualified module name : the repository name '{0}' does not exist.
    InvalidNameUnderUbuntu                             = {0} name is invalid under Ubuntu : '{1}'. The '.psd1 and '.psm1' files  must have the same casing, otherwise the search by Import-Module will fail
'@