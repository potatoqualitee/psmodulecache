#PSModuleCache.psm1
#Requires -Modules @{ ModuleName="powershellget"; ModuleVersion="1.6.6" }

#VSCode extensions recommendation : https://marketplace.visualstudio.com/items?itemName=aaron-bond.better-comments

# Note:
#
#  !! This module assumes the existence of the following environment variables: $env:RUNNER_OS and $env:GITHUB_WORKFLOW.
#
#  You can target a version lower than the one in the image: pester:5.3.0
#  Existing modules in the image are not excluded, they can be installed like the others.
#  Get-Module does not display the prerelease part of a version number.
#  Save-Module uses a [Version] as directory name for a prerelease module.
#
# Known issues : About AllowPrerelease - https://github.com/PowerShell/PowerShellGetv2/issues/517

$script:WarningPreference = 'Continue'

Enum CacheType{
   Immutable
   Updatable
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12

Import-LocalizedData -BindingVariable PSModuleCacheResources -FileName PSModuleCache.Resources.psd1 -ErrorAction Stop

New-Variable -Name ActionVersion -Option ReadOnly -Scope Script -Value '6.0'

New-Variable -Name Delimiter -Option ReadOnly -Scope Script -Value '-'

#Lists the names of registered repositories, by default PsGallery.
#Additional repositories are added beforehand in a dedicated 'Step'.
New-Variable -Name RepositoryNames -Option ReadOnly -Scope Script -Value @(Get-PSRepository | Select-Object -ExpandProperty Name)
New-Variable -Name IsThereOnlyOneRegisteredRepository -Option ReadOnly -Scope Script -Value @($script:RepositoryNames.Count -eq 1)

New-Variable -Name PsWindowsModulePath -Option ReadOnly -Scope Script -Value "$env:ProgramFiles\WindowsPowerShell\Modules"
New-Variable -Name PsWindowsCoreModulePath -Option ReadOnly -Scope Script -Value "$env:ProgramFiles\PowerShell\Modules"
New-Variable -Name PsLinuxCoreModulePath -Option ReadOnly -Scope Script -Value '/usr/local/share/powershell/Modules/'

New-Variable -Name CacheFileName -Option ReadOnly -Scope Script -Value 'PSModuleCache.Datas.xml'

#We do not check all the characters returned by the GetInvalidFileNameChars() API.
New-Variable -Name InvalidCharsExceptBackslash -Option ReadOnly -Scope Script -Value '"|\<|\>|\||\*|\?|/|\:'

#Contains strings detailing syntax or functionnal rules that are violated in the content of the 'module-to-cache' parameter.
$script:FunctionnalErrors = [System.Collections.ArrayList]::New()

#region Keygen
function Add-FunctionnalError {
   #Log functional errors.
   #GHA (GitHub Action) stop the step as soon as an error is triggered.
   #We want to analyze all the module information before stopping the processing.
   #See default : https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#exit-codes-and-error-action-preference
   #So we can't use Write-Error (the behavior of a non-critical error in this context).
   Param($Message)

   $script:FunctionnalErrors.Add($Message) > $null
}

function Get-PowerShellGetVersion {
   # Separates Version from Prerelease string (if needed) and validates each.
   #Adapted from :
   # https://github.com/PowerShell/PowerShellGetv2/blob/master/src/PowerShellGet/private/functions/ValidateAndGet-VersionPrereleaseStrings.ps1
   #
   #Note :
   #The original code reconstructs the version number (see FullVersion),
   # the returned version number may no longer correspond to the one passed as a parameter.
   #
   #See to :
   # https://learn.microsoft.com/en-us/powershell/scripting/gallery/concepts/module-prerelease-support?view=powershell-5.1
   Param
   (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Version
   )

   #In the original code this parameter is used by Update-ModuleManifest
   #It is not used here, but the code references it using implicit conversions
   [string] $Prerelease = [string]::Empty

   # Scripts scenario
   if ($Version -match '-' -and -not $Prerelease) {
      $Version, $Prerelease = $Version -split '-', 2
   }

   # Remove leading hyphen (if present) and trim whitespace
   if ($Prerelease -and $Prerelease.StartsWith('-') ) {
      $Prerelease = $Prerelease -split '-', 2 | Select-Object -Skip 1
   }
   if ($Prerelease) {
      $Prerelease = $Prerelease.Trim()
   }

   # only these characters are allowed in a prerelease string
   $validCharacters = "^[a-zA-Z0-9]+$"
   $prereleaseStringValid = $Prerelease -match $validCharacters
   if ($Prerelease -and -not $prereleaseStringValid) {
      #Error for the Github Action runner
      $message = $PSModuleCacheResources.InvalidCharactersInPrereleaseString -f $Prerelease
      Add-FunctionnalError -Message $Message
      #Error for the caller
      throw "Get-PowerShellGetVersion : $Message"
   }

   # Validate that Version contains exactly 3 parts
   if ($Prerelease -and -not ($Version.ToString().Split('.').Count -eq 3)) {
      $message = $PSModuleCacheResources.IncorrectVersionPartsCountForPrereleaseStringUsage -f $Version
      Add-FunctionnalError -Message $Message
      throw "Get-PowerShellGetVersion : $Message"
   }

   # try parsing version string
   [Version]$VersionVersion = $null
   if (-not ( [System.Version]::TryParse($Version, [ref]$VersionVersion) )) {
      $message = $PSModuleCacheResources.InvalidVersion -f ($Version)
      Add-FunctionnalError -Message $message
      throw "Get-PowerShellGetVersion : $Message"
   }

   $fullVersion = if ($Prerelease) { "$VersionVersion-$Prerelease" } else { "$VersionVersion" }

   $results = @{
      Version     = "$VersionVersion"
      Prerelease  = $Prerelease
      FullVersion = $fullVersion
   }
   return $results
}

function Test-Version {
   #Return $true for a valid PowerShellGet version (with or without prerelease).
   param(
      [string] $Version
   )
   try {
      Get-PowerShellGetVersion -Version $Version > $null
      return $true
   } catch {
      return $false
   }
}

function Test-PrereleaseVersion {
   #Return $true for a PowerShellGet version with a prerelease.
   param( [string]$Version )
   try {
      $PowerShellGetVersion = Get-PowerShellGetVersion -Version $Version
      return $PowerShellGetVersion.Prerelease -ne ([string]::Empty)
   } catch {
      #$Version has invalid syntax
      return $false
   }
}

function ConvertTo-Version {
   #return a PowerShellGet version number without the prerelease
   #Save-Module uses a [Version] as directory name for a prerelease module.
   param(
      [string]$Version
   )
   #Note : Here one should only receive valid and authorized version numbers.

   $PowerShellGetVersion = Get-PowerShellGetVersion -Version $Version

   #For '01.1.1' return '1.1.1'
   #For '1.2.3--' return '1.2.3'
   #for '1.2.3.4--' return '1.2.3.4'
   return $PowerShellGetVersion.Version
}

function Test-RepositoryName {
   #Repository Qualified Module Name : Repository name cannot be empty and must exist
   param($RepositoryName)

   $Result = $RepositoryName.Trim() -eq [string]::Empty
   if ($Result) {
      Add-FunctionnalError -Message ( $PSModuleCacheResources.RQMN_RepositoryPartInvalid )
      $Result = $false
   } else {
      $Result = $RepositoryName -in $RepositoryNames
      if (-not $Result)
      { Add-FunctionnalError -Message ( $PSModuleCacheResources.RQMN_RepositoryNotExist -f $RepositoryName) }
   }
   $Result
}

Function Get-RepositoryQualifiedModuleName {
   param( $ModuleName )
   #If the module name, without the version number, is fully qualified then it is split into its component parts.
   #If repository name exists, we return a custom object, otherwise we return $null
   # Example:  RepositoryName\ModuleName OR ModuleName OR RepositoryName\ModuleName:1.2.3 OR ModuleName:1.2.3
   #
   #Note :
   # Assume modulename is not an empty string, this case is tested before calling this function.

   $Result = $null
   $Names = $ModuleName.Split('\')
   $Count = $Names.Count

   if ($Count -eq 1) {
      #syntax: module name only
      $Result = [PSCustomObject]@{
         RepositoryName = $Null
         ModuleName     = $ModuleName
      }
   } elseif ($Count -eq 2) {
      # The '\' character is forbidden in a nuget package name, therefore in a module name.
      #   https://github.com/NuGet/NuGet.Client/blob/dev/src/NuGet.Core/NuGet.Packaging/PackageCreation/Authoring/ManifestFile.cs#L21
      $RepositoryName = $Names[0]
      $isValidRepositoryName = Test-RepositoryName $RepositoryName
      if ($isValidRepositoryName) {
         #syntax: repository name AND module name
         $Result = [PSCustomObject]@{
            RepositoryName = $RepositoryName
            ModuleName     = $Names[1]
         }
      }
   } else {
      Add-FunctionnalError -Message ( $PSModuleCacheResources.RQMN_InvalidSyntax -f $ModuleName )
   }
   return $Result
}

Function New-FindModuleParameters {
   #Analyze a module name and build a hashtable for 'Find-ModuleCacheDependencies' parameters.
   #When $Name use the 'Repository Qualified Module Name' syntax we return only the module name.
   param (
      $Name,
      $Version
   )

   $RQMN = Get-RepositoryQualifiedModuleName $Name
   if ($null -eq $RQMN) {
      #Syntax error. We analyze the next module
      return $null
   }
   $isRepositoryQualified = $null -ne $RQMN.RepositoryName

   if ($isRepositoryQualified)
   { $Repository = $RQMN.RepositoryName }
   else
   { $Repository = $script:RepositoryNames }


   #We are looking for the version currently published into the repositories or into the specified repository.
   #In case of new version, the cache key changes and will trigger the creation of a new cache.
   Return @{
      Name                = $RQMN.ModuleName
      RequiredVersion     = $Version
      AllowPrerelease     = $AllowPrerelease
      Repository          = $Repository
      RepositoryQualified = $isRepositoryQualified
   }
}

function New-ModuleToCacheInformation {
   #creates an object containing the information of a module
   param(
      #Module name
      [Parameter(Mandatory, position = 0)]
      [AllowEmptyString()]
      [string]$Name,

      [Parameter(Mandatory, position = 1)]
      [AllowEmptyString()]
      #Contains the name of the repository where the module was found.
      [string] $Repository,

      #Versioning management, for this module
      # Allows to build the key for this module (with or without version).
      # Only $Action.Updatable determines the cache type.
      [Parameter(Mandatory, position = 2)]
      [CacheType]$Type,

      #Requested version or an empty string.
      #Can be in [Version] (Powershell v5.1) or [semver] format (Powershell >= v6.0 ) or empty.
      [Parameter(position = 3)]
      [string]$Version,

      #Dependencies of this module.
      #They are saved in the cache but are not used in the key name.
      $Dependencies,

      #Save either a prerelease version for the module ($true) or a stable version ($false).
      [switch]$AllowPrerelease,

      #Determines if the module name uses the syntax 'Repository qualified module name'
      [switch]$RepositoryQualified
   )

   [pscustomobject]@{
      PSTypeName                      = 'ModuleToCacheInformation'
      Name                            = $Name
      Repository                      = $Repository
      Type                            = $Type
      Version                         = $Version
      AllowPrerelease                 = $AllowPrerelease
      Dependencies                    = $Dependencies

      #For a value $true, the module is searched for in the repository specified (see RQMN syntax).
      #For a value $false, the module is searched in all existing repositories.
      isRepositoryQualifiedModuleName = $RepositoryQualified.IsPresent
   }
}

function New-ModuleDependencyInformation {
   #creates an object containing the information of a dependent module
   param(
      #The requested module (Repo-Name-Version)
      [Parameter(Mandatory, position = 0)]
      [string]$MainModule,

      #Module name
      [Parameter(Mandatory, position = 1)]
      [string]$Name,


      [Parameter(Mandatory, position = 2)]
      [string]$Version,

      [Parameter(Mandatory, position = 3)]
      [string]$RepositoryName
   )
   [pscustomobject]@{
      PSTypeName = 'ModuleDependencyInformation'
      MainModule = $MainModule
      Name       = $Name
      Version    = $Version
      Repository = $RepositoryName
   }
}


function Find-ActionModule {
   #Build and return a 'ModuleToCacheInformation' object containing informations about a module name to cache.
   #This object contains the module dependencies and the repository name where the module was found.

   param (
      [Parameter(Mandatory, position = 0)]
      [string]$Name,

      [Parameter(Mandatory, position = 1)]
      [CacheType]$Type,

      [Parameter(position = 2)]
      [string] $Version
   )

   function ConvertTo-ModuleDependencyInformation {
      #Convert a 'PSRepositoryItemInfo' object to a 'ModuleDependencyInformation' object.
      #Return a collection of dependencies or an empty collection.
      param( $ModulesFound )

      $Dependencies = [System.Collections.ArrayList]::New()

      if ($ModulesFound.Count -gt 1) {
         $List = [System.Collections.ArrayList]::new($ModulesFound)
         $MainModule = $List | Where-Object { $_.isMainModule -eq $true }
         $List.Remove($MainModule)

         #Only the primary module is searched, the others are dependencies, we therefore distinguish the dependent modules
         #so as not to perform a Save-Module with these names.
         #Unlike Find-Module, Save-Module saves dependencies from the same repository.The cache needs to know the path of the dependencies

         #Primary key uniqueness
         $MainModuleKey = '{0}-{1}-{2}' -F $MainModule.Repository, $MainModule.Name, $MainModule.Version
         foreach ($Current in $List) {
            $MdiParameters = @{
               MainModule     = $MainModuleKey
               Name           = $Current.Name #We use the name of the Nuget package which is case sensitive.
               Version        = $Current.Version
               RepositoryName = $Current.Repository
               #Note : The 'AdditionalMetadata' property provides the information 'isAbsoluteLatestVersion' and 'isLatestVersion'.
               # see https://github.com/PowerShell/PowerShellGetv2/issues/95
               #
               #!! With PowerShellGetv2 'isAbsoluteLatestVersion' and 'isLatestVersion' properties do not work correctly with a local repository...
            }
            $Dependencies.Add( (New-ModuleDependencyInformation @MdiParameters) ) > $null
         }
      }
      Write-Output $Dependencies -NoEnumerate
   }

   $Parameters = New-FindModuleParameters -Name $Name -Version $Version

   if ($null -eq $parameters) {
      #Syntax error. We analyze the next module
      return $null
   }

   $RepoItemInfo = Find-ModuleCacheDependencies @Parameters

   $isRepositoryQualified = $Parameters.RepositoryQualified

   if ($null -ne $RepoItemInfo) {
      $MainModule = $RepoItemInfo | Where-Object { $_.Name -eq $Parameters.Name }
      $Version = $MainModule.Version
      $ModuleName = $MainModule.Name #We use the name of the Nuget package which is case sensitive.
      $Repository = $MainModule.Repository
   } else {
      # Error
      #We build and emit the object, but the 'Test-FunctionnalError' function will stop the processing.
      $ModuleName = $Name
      $Version, $Repository = $null
   }
   $MtciParameters = @{
      Name                = $ModuleName
      Repository          = $Repository
      Type                = $Type
      Version             = $Version
      AllowPrerelease     = $AllowPrerelease
      Dependencies        = (ConvertTo-ModuleDependencyInformation $RepoItemInfo)
      RepositoryQualified = $isRepositoryQualified
   }

   #We can specify a module without version information, neither updatable nor required
   New-ModuleToCacheInformation @MtciParameters
}

function Split-ModuleCacheInformation {
   # Split a string containing versioning information for a module and check the syntax rules.
   # Example: ModuleName or ModuleName:1.0.1 or ModuleName:: or prefixed with a repository name : RepositoryName\ModuleName:1.0.1
   Param(
      $ModuleCacheInformation,
      [switch]$AllowPrerelease
   )

   if ($ModuleCacheInformation -eq [string]::Empty) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.EmptyModuleName -F $ModuleCacheInformation)
      #The processing of the other module information is continued, which makes it possible to list all the syntax errors.
      return
   }

   #Note: The module name 'InvokeBuild.5.9.0' is valid for PowershellGet.
   if ($ModuleCacheInformation -match '^(?<Name>.*?)::(?<Version>.*){0,1}$') {
      #We are looking for the latest version available in the module repository
      $Name = $Matches.Name
      if ($Name -eq [string]::Empty) {
         Add-FunctionnalError -Message ($PSModuleCacheResources.EmptyModuleName -F $ModuleCacheInformation)
         return #In this case the following instructions will fail
      }
      #todo Enhancement : The 'RQMN' syntax is analyzed later in the code...
      if ($Name -match $InvalidCharsExceptBackslash ) {
         Add-FunctionnalError -Message ($PSModuleCacheResources.InvalidModuleNameSyntax -F $Name, $ModuleCacheInformation)
         return
      }

      if ($Matches.Version -ne [string]::Empty) {
         Add-FunctionnalError -Message ($PSModuleCacheResources.UpdatableModuleCannotContainVersionInformation -F $ModuleCacheInformation)
         #Here we are not trying to find out if the version text is really a version type.
         return
      }

      #We are looking for the version currently published into the repositories or into the specified repository.
      #In case of new version, the cache key changes and will trigger the creation of a new cache.
      #todo According to the syntax rule of an updateable module, the version part will always be empty.
      $cacheinfo = Find-ActionModule -Name $Name -Type 'Updatable' -Version $Version
   } else {
      #We use the string as it is
      $Name, $Version = $ModuleCacheInformation.Split(':')

      if ($Name -match $InvalidCharsExceptBackslash ) {
         Add-FunctionnalError -Message ($PSModuleCacheResources.InvalidModuleNameSyntax -F $Name, $ModuleCacheInformation)
         return
      }
      #if a version is specified, it must be filled in.
      if ($ModuleCacheInformation -match ':') {
         if ($Name -eq [string]::Empty) {
            Add-FunctionnalError -Message ($PSModuleCacheResources.EmptyModuleName -F $ModuleCacheInformation)
            return  #In this case the following instructions will fail
         }

         if ($Version -eq [string]::Empty) {
            Add-FunctionnalError -Message ($PSModuleCacheResources.MissingRequiredVersion -F $ModuleCacheInformation)
            return
         }
         if (-not (Test-Version -Version $Version)) {
            Add-FunctionnalError -Message ($PSModuleCacheResources.InvalidVersionNumberSyntax -F $Version, $ModuleCacheInformation)
            return
         }

         $isPrereleaseVersion = Test-PrereleaseVersion -Version $Version

         if ($AllowPrerelease) {
            #We want to install a prerelease, example 'PnP.PowerShell:1.11.22-nightly'
            #if the module is a prerelease and a version exists, it must be a prerelease.
            if (-not $isPrereleaseVersion) {
               Add-FunctionnalError -Message ($PSModuleCacheResources.ModuleMustContainPrerelease -F $version)
               return
            }
         } elseif ($isPrereleaseVersion) {
            #if the module is not a prerelease and a version exists, it must not be a prerelease.
            Add-FunctionnalError -Message ($PSModuleCacheResources.ModuleCannotContainPrerelease -F $version)
            return
         }
      }

      #We can specify a module without version information, neither updatable nor required
      $cacheinfo = Find-ActionModule -Name $Name -Type  'Immutable' -Version $Version
   }

   return $cacheinfo
}

Function Test-ModuleNameDuplication {
   <#
   There can be no module name duplication in 'modules-to-cache' or 'modules-to-cache-prerelease'.
   There is no check on grouping module names present in 'modules-to-cache' and in 'modules-to-cache-prerelease',
   but some cases will be filtered by the 'Remove-ModulePathDuplication' function, example 'PSGallery\InvokeBuild:5.9.0,Invokebuild:5.9.0'.

   Finally for the following syntax 'PSGallery\InvokeBuild:5.9.0,InvokeBuild::', if the latest stable version is version 5.9.0 we obtain a single version
   otherwise two versions.
#>
   param (
      [string[]] $Modules
   )

   #We consider the combination 'InvokeBuild,InvokeBuild::' as identical to 'InvokeBuild,InvokeBuild'
   $ModulesNames = @($Modules | ForEach-Object { $_ -Replace '::', '' })

   if ($script:IsThereOnlyOneRegisteredRepository) {
      #If the repository part is equal to the existing repository name,
      # in this case we consider the combination 'PsGallery\Pester,Pester' as identical to 'Pester,Pester'
      $ModulesNames = @($ModulesNames | ForEach-Object {
            $RQMN = Get-RepositoryQualifiedModuleName $_
            if ($null -ne $RQMN) {
               if ($RQMN.RepositoryName -eq $RepositoryNames[0]) {
                  $RQMN.ModuleName
               } else {
                  $_
               }
            } else {
               #Either we already have a functional error or it will be triggered further
               $_
            }
         })
   }

   $NameGroups = $ModulesNames | Group-Object
   # A module name group must have only one item.
   # We return the module names that are duplicated
   Return @($NameGroups | Where-Object { $_.Count -gt 1 })
}

function New-ModuleCache {
   #Build a modulecache object from Action parameters.
   param (
      #PSCustomObject with PSTypeName 'ModuleCacheParameter'
      $Action
   )

   function New-Key {
      #Either an existing cache key name or a new cache key name is returned.
      #In this case if there is a cache with the old key, the release rule will apply:
      # GitHub will remove any cache entries that have not been accessed in over 7 days.

      #TODO  Enhancement
      #1 - The following setting does not specify the version in the key:
      #     @{Modules = 'LatestPrereleaseVersion'; PrereleaseModules = 'LatestPrereleaseVersion'; Shells = 'powershell,pwsh'; Updatable = $false }
      # return "Windows-6.0-Immutable-powershell-pwsh-LatestPrereleaseVersion-LatestPrereleaseVersion"
      #Implicitly the latest stable and the latest prerelease
      #
      #2 - The following setting specifies the name twice but only one is recorded because , the both parameter return the same version.
      #       @{Modules = 'LatestStableVersion'; PrereleaseModules = 'LatestStableVersion'; Shells = 'powershell,pwsh'; Updatable = $false }
      # return "Windows-6.0-Immutable-powershell-pwsh-LatestStableVersion-LatestStableVersion"

      param($ModuleCacheInformation)
      if (($ModuleCacheInformation.Type -eq [CacheType]::Immutable) -and ($ModuleCacheInformation.Version -eq [string]::Empty)) {
         #An immutable module with no version number required
         return $ModuleCacheInformation.Name
      } else {
         #An updatable module or an immutable module with a version number required
         '{0}:{1}' -f $ModuleCacheInformation.Name, $ModuleCacheInformation.Version
      }
   }

   function Split-ModuleParameter {
      #return one or more 'ModuleToCacheInformation' objects.
      param(
         [bool]$ContainerJob,
         $modules,
         [switch]$AllowPrerelease
      )
      foreach ($module in $modules) {
         #Check syntax rules
         $cacheinfo = Split-ModuleCacheInformation -ModuleCacheInformation $module -AllowPrerelease:$AllowPrerelease
         Write-Output $cacheinfo
      }
   }

   function Join-ModuleName {
      #Build the cache key
      #Use the caller variables
      param()

      $KeyName = [System.Text.StringBuilder]::New()

      if ($Action.PrefixIdentifier) {
         $KeyName.Append($env:GITHUB_WORKFLOW + $Delimiter) > $null
      }

      $Prefix = "${env:RUNNER_OS}$Delimiter$($ActionVersion)$Delimiter$($Action.CacheType)$Delimiter$($Action.ShellsParameter -join $Delimiter)"
      $KeyName.Append($Prefix) > $null
      $KeyName.Append($Delimiter) > $null

      $OFS = $Delimiter
      if ($Action.Updatable) {
         #Builds the key specifying the latest available version number if requested
         #Note : Prerelease information is not used to build a key name.
         #       The repository name is not removed if the 'Repository Qualified Module Name' syntax is used..
         $Keys = foreach ($current in $ModuleCacheInformations) {
            New-Key -ModuleCacheInformation $current
         }
         $KeyName.Append("$Keys") > $null
      } else {
         #We use the string as it is.
         # All this splitting and joining accomodates for powershell and pwsh
         if ($StableModules.Count -gt 0) {
            $KeyName.Append("$StableModules") > $null
         }

         if ($PrereleaseModules.Count -gt 0) {
            if ($StableModules.Count -gt 0) {
               $KeyName.Append($Delimiter) > $null
            }
            $KeyName.Append("$PrereleaseModules") > $null
         }
      }
      return $KeyName.ToString()
   }

   if (-not $Action.ShellsParameter.IsAuthorizedShells) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.MustBeAnAuthorizedShell -F $Action.ShellsParameter)
   }

   $SyntaxError = @()

   if ($Action.ModulesParameter -ne [string]::Empty) {
      $SyntaxError += $Action.ModulesParameter
   }

   if ($Action.PrereleaseModulesParameter -ne [string]::Empty) {
      $SyntaxError += $Action.PrereleaseModulesParameter
   }

   $ofs = ' / '

   if ($Action.CacheType -eq 'Immutable' -and $Action.isCacheUpdatable) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.ImmutableCacheCannotContainUpdatableInformation -F "$SyntaxError")
   }

   if ($Action.CacheType -eq 'Updatable' -and (-not $Action.isCacheUpdatable)) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.UpdatableCacheMustContainUpdatableInformation -F "$SyntaxError")
   }

   $OFS = ' , '
   $StableModules = $Action.ModulesParameter.ToArray()

   $DuplicateModuleName = Test-ModuleNameDuplication $StableModules
   if ($DuplicateModuleName.Count -gt 0) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.StableModuleNamesAreDuplicated -F "$($DuplicateModuleName.Name)")
   }

   $PrereleaseModules = $Action.PrereleaseModulesParameter.ToArray()
   $DuplicateModuleName = Test-ModuleNameDuplication $PrereleaseModules
   if ($DuplicateModuleName.Count -gt 0) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.PrereleaseModuleNamesAreDuplicated -F "$($DuplicateModuleName.Name)")
   }

   $ModuleCacheInformations = @(
      Split-ModuleParameter -ContainerJob $Action.ContainerJob -modules $StableModules
      Split-ModuleParameter -ContainerJob $Action.ContainerJob -modules $PrereleaseModules  -AllowPrerelease
   )

   #The serialization depth use default value 2
   return  [pscustomobject]@{
      PSTypeName              = 'ModuleCache'
      Key                     = Join-ModuleName

      #We make sure to save the latest prerelease version in case of request for two versions :
      ModuleCacheInformations = @($ModuleCacheInformations | Sort-Object Repository, Name, Version)

      PrefixIdentifier        = $Action.PrefixIdentifier
      #To save a module, we use the PSModulePath associated with the shells and the module name.
      #And indirectly the version (not a semver), since you can request at least two versions of the same module.
      ModuleSavePaths         = Get-ModuleSavePath -ContainerJob $Action.ContainerJob  -Shells $Action.ShellsParameter
   }
}

function Test-FunctionnalError {
   if ($script:FunctionnalErrors.Count -gt 0) {
      $sbProcess = { Write-Host "$($PSStyle.Foreground.Red)$PSItem$($PSStyle.Reset)" }

      if ($PSEdition -eq 'Desktop') {
         Write-Warning 'List of errors :'
         $sbProcess = { Write-Warning $_ }
      } else {
         Write-Host "$($PSStyle.Foreground.Red)List of errors :$($PSStyle.Reset)"
      }
      $script:FunctionnalErrors | ForEach-Object $sbProcess
      throw "Check the setting of the 'psmodulecache' Action."
   }
}

function Get-ModuleCache {
   <#
.Synopsis
   Called from 'Action.yml'.
   return a 'ModuleCache' object from Action parameters or a error list.
#>
   param (
      #pscustomobject with pstypename 'ModuleCacheParameter'
      $Action,
      [switch]$Pester
   )
   $script:FunctionnalErrors.Clear()
   $ModulesCache = New-ModuleCache -Action $Action

   if ($Pester) {
      #Since we choose not to modify the default error behavior, for Pester we will test strings and not ErrorRecords.
      return , $script:FunctionnalErrors
   }
   Test-FunctionnalError
   Write-Output $ModulesCache
}
#endregion

#region ModulePath
function Get-ModuleSavePath {
   <#
.Synopsis
   return one or more module full paths.
   It is assumed that the parameters are valid and have been tested before calling this function.
#>
   param(
      [bool]$ContainerJob,

      #Depending on the implicit rule of the 'Shell' parameter of the Action, contains either 'powershell' or 'pwsh' or both.
      [string[]]$Shells
   )

   if ($env:RUNNER_OS -eq 'Windows') {
      if ('powershell' -in $Shells) {
         Write-Output $script:PsWindowsModulePath
      }

      if ('pwsh' -in $Shells) {
         Write-Output $script:PsWindowsCoreModulePath
      }

   } elseif ($env:RUNNER_OS -in @('Linux', 'MacOS')) {
      # Ensure 'sudo' exists
      if (-not $ContainerJob) {
         $null = sudo chown -R runner $script:PsLinuxCoreModulePath
      }
      Write-Output $script:PsLinuxCoreModulePath
   } else {
      throw "`$env:RUNNER_OS ('$env:RUNNER_OS') is empty or unknown."
   }
}

function New-ModuleSavePath {
   <#
.Synopsis
   Returns the module paths to put in the cache

   Called from Action.yml, this paths are used by actions/cache
#>
   param( $ModulesCache )

   #Original information is stored with duplicate paths.
   #$ModuleCacheInformations contains the requested modules from the parameters 'module-to-cache' and 'module-to-cache-prerelease'
   $ModuleSavePathsFiltered = Remove-ModulePathDuplication -Module $ModulesCache.ModuleCacheInformations

   foreach ($cacheinfo in $ModuleSavePathsFiltered) {

      $ModuleName = $cacheinfo.Name
      # the new version number is added to the name of the save path, if it is specified.
      # We manage the following cases:
      #     'Pester::' , 'Pester:5.3.0-rc1', 'Pester:5.3.0'
      #
      # But we do not manage the following case:
      #  modules-to-cache: 'Pester'. In this case the version is the latest stable version.
      #  modules-to-cache-prerelease:'Pester'. In this case the version the last published version.
      $Version = $cacheinfo.Version
      $isVersion = $Version -ne [String]::Empty

      if ($isVersion) {
         #Adapting the version number for the call of Save-Module cmdlet.
         $Version = ConvertTo-Version $Version
      }

      #The module path of each requested shell.
      foreach ($ModuleSavePath in $ModulesCache.ModuleSavePaths) {
         $Path = [System.IO.Path]::Combine($ModuleSavePath, $ModuleName)
         if ($isVersion) {
            [System.IO.Path]::Combine($Path, $Version)
         } else {
            $Path
         }
      }
   }
}

function ConvertTo-YamlLineBreak {
   #unused function, we keep it for the history
   <#
.Synopsis
   Convert an array of string to a unique YAML string.
#>
   param ($Collection)
   #https://github.com/orgs/community/discussions/26288

   $ofs = '%0A' #https://yaml.org/spec/1.2.2/#54-line-break-characters
   return "$Collection"
}

Function Test-RepositoryDuplication {
   #Returns $True if the searched module exists in several repositories
   #The module and its dependencies must be in the same repository
   param(
      #Contains information about a module
      $ModulesFound
   )

   $GroupRepository = $ModulesFound | Group-Object -Property 'Repository'
   return $GroupRepository.Values.Count -gt 1
}

Function Get-ModuleNameDuplicated {
   #Returns the module name duplicated in several repositories
   # For a module, we can retrieve modules from two repositories, this is an error.
   #We must specify which one to choose.
   param($ModulesFound)

   $NameGroups = $ModulesFound | Group-Object -Property 'Name'
   # A module group must have only one item.
   # We return the module names that are duplicated
   Return @($NameGroups | Where-Object { $_.Count -gt 1 })
}

function Find-ModuleCacheDependencies {
   #We search for a module in order to retrieve :
   #  - its version number (the cache key may change),
   #  - the syntax of the Nuget package name and
   #  - its dependencies.
   #
   #Notes:
   # 'Find-module Name' always return the last stable version, even if the last published version is a prerelease
   # 'Find-module Name -AllowPrerelease' can return the last stable version or the last prerelease.
   #  The management of external dependencies (PrivateData .PSData.ExternalModuleDependencies) is the responsibility of the user.

   [CmdletBinding()]
   param(
      $Name,
      $Repository,
      $RequiredVersion,
      [switch]$AllowPrerelease,
      [switch]$RepositoryQualified
   )
   Function Remove-ModuleDependencyDuplicate {
      #The Module 'AZ' has dependencies using the same module (Az.Accounts) but different version.
      #In this case Find-module returns this module several times.
      param( $ModulesFound )
      $Result = @($ModulesFound |
         Group-Object -Property 'Name', 'Version', 'Repository' |
         ForEach-Object { $_.Group[0] }
      )
      Write-Output $Result -NoEnumerate
   }

   try {

      if ([string]::IsNullOrEmpty($RequiredVersion)) {
         #If provided, retrieved the requested version, otherwise the last one.
         $PSBoundParameters.Remove('RequiredVersion')  > $null
      }

      $isModuleNameRepositoryQualified = $RepositoryQualified.IsPresent
      $PSBoundParameters.Remove('RepositoryQualified') > $null

      Write-Debug "Find-ModuleCacheDependencies bound parameters $( $PsBoundParameters.GetEnumerator() | Out-String -Width 512)"
      Write-Debug "IsThereOnlyOneRegisteredRepository : $script:IsThereOnlyOneRegisteredRepository"
      Write-Debug "isModuleNameRepositoryQualified :  $isModuleNameRepositoryQualified"

      if ($script:IsThereOnlyOneRegisteredRepository -or $isModuleNameRepositoryQualified) {
         Write-Debug "`tONLY ONE repository"

         #We are looking for a module name.
         #In this case $Repository is correctly filled in and contains ONLY ONE item.
         $ModulesFound = @(Find-Module @PSBoundParameters -IncludeDependencies -ErrorAction Stop)

         #Note : PS Core change Group-Object -> As part of the performance improvement, Group-Object now returns a sorted listing of the groups.
         #Under Windows Powershell the first element is always the main module the others are dependencies, for PSCore we must find it into the list...
         $ModulesFound | Add-Member -MemberType NoteProperty -Name isMainModule -Value $false
         $ModulesFound[0].isMainModule = $true

         $ModulesFound = Remove-ModuleDependencyDuplicate -ModulesFound $ModulesFound
      } else {
         Write-Debug "`tSEVERAL repositories"

         #We are looking for a module name, it can exist in several repositories.
         #In this case $Repository contains ALL names of the declared repositories.
         $ModulesFound = @(Find-Module @PSBoundParameters -IncludeDependencies -ErrorAction Stop)
         $ModulesFound | Add-Member -MemberType NoteProperty -Name isMainModule -Value $false
         $ModulesFound[0].isMainModule = $true

         $ModulesFound = Remove-ModuleDependencyDuplicate -ModulesFound $ModulesFound

         $DuplicateModuleName = Get-ModuleNameDuplicated $ModulesFound
         if ($DuplicateModuleName.Count -gt 0) {
            #CONFLICT case 1
            # For a module, we can retrieve modules from two repositories, this is an error. We must specify which one to choose.
            # Note :
            # For a module, Find-Module returns all modules found in all repositories.
            # But in this case Save-Module raises an exception not knowing which repository to use.
            # Use case, see the module 'String'
            $OFS = ' , '
            $Message = $PSModuleCacheResources.ModuleExistsInSeveralRepositories -F $DuplicateModuleName.Name , "$($DuplicateModuleName.Group.Repository)"
            Add-FunctionnalError -Message $Message
            return $null
         } elseif (Test-RepositoryDuplication $ModulesFound) {
            #BUG
            #The module and its dependencies are in two repositories.
            #Use case,see the module 'DuplicateByDependency'
            #See :https://github.com/PowerShell/PowerShellGetv2/issues/697
            $OFS = ' , '
            $Message = $PSModuleCacheResources.ModuleDependenciesExistsInSeveralRepositories -F $ModulesFound[0].Name
            Add-FunctionnalError -Message $Message
            return $null
         }
      }
      #We get a module. At this stage there can be no duplicates.
      Write-Output $ModulesFound -NoEnumerate

   } catch [System.Exception] {
      #Same exception for cases where the module does not exist or the requested version does not exist.
      if (($_.CategoryInfo.Category -eq 'ObjectNotFound') -and ($_.FullyQualifiedErrorId -Match '^NoMatchFoundForCriteria')) {
         #if the URI of a repository is wrong, Find-Module generates a warning then an exception.
         # We therefore do not know the real cause of the error.
         Add-FunctionnalError -Message ($PSModuleCacheResources.UnknownModuleName -F $Name, "$Repository")
         return $null
      } else {
         throw $_
      }
   }
}
#endregion

#region SaveModule
Function Remove-ModulePathDuplication {
   #We check the possible duplication in order to avoid redundant calls to Save-Module.
   #The name duplication test is case insensitive.
   #We delete duplicate module entries having the same name and the same version.

   #!! For the same module, the group considers the prereleases as different versions: 5.3.0 and 5.3.0-beta1
   #   'modules-to-cache:Pester:5.3.0'
   #   'modules-to-cache-prerelease:Pester:5.3.0-beta1'
   #We have two versions but only one save directory.

   param( $ModuleCacheInformations )

   $Modules = foreach ($cacheinfo in $ModuleCacheInformations) {
      #When MainModule is $null this is the requested module
      $CacheInfo | Select-Object MainModule, Name, Version, Repository
      $CacheInfo.Dependencies
   }

   #If a name and a version are identical for a primary module and a dependency, we take the first of the group without distinction
   $Modules | Group-Object Name, Version | ForEach-Object { $_.Group[0] }
}

function Test-ModuleNaming {
   #We test the naming of a module.
   #see : https://github.com/PowerShell/PowerShell/issues/17342
   #      https://github.com/PowerShell/PSResourceGet/issues/1446
   #      https://github.com/Splaxi/PSNotification/issues/15
   param(
      #Name of module directory to check.The name come from the nuget package
      $ModuleName,

      [string]$Version,

      #Path where the module was saved by Save-ModuleCache.
      $SavePath
   )
   if ([string]::IsNullOrEmpty($Version))
   { throw "Assert: Test-ModuleNaming '-Version' parameter must be filled in." }

   #The number of version must not contains prelease information
   $Version = (Get-PowerShellGetVersion $Version).Version

   $ModuleRegex = [RegEx]::Escape($ModuleName) + '\.(psd1|psm1|ni\.dll|dll|exe)$'

   $Files = Get-ChildItem "$SavePath\$ModuleName\$Version\$ModuleName.*" -Include *.psd1, *.psm1, *.ni.dll, *.dll, *.exe
   If ($Files.Count -eq 0) {
      Write-Warning "The module directory must contain at least one file of one of these types .psd1 or .psm1 or .ni.dll or .dll or .exe : '$SavePath\$ModuleName\$Version'"
      #This is not a naming error
      #NOTE : NUGET.EXE -> Error NU5017: Cannot create a package that has no dependencies nor content.
      return $true
   }

   #We assume that the nuget package contains at least one module file.
   Foreach ($File in $Files) {
      $isNamingCorrect = $File -cMatch $ModuleRegex
      switch ($File.Extension) {
         #If a correctly named manifest exists we quit without warning otherwise we warn and then we quit.
         #If no manifest exists we continue the search.
         '.psd1' { if (-not $isNamingCorrect) { Write-Warning ($PSModuleCacheResources.InvalidNameUnderUbuntu -F 'Module manifest', $file) }; return }
         '.psm1' { if (-not $isNamingCorrect) { Write-Warning ($PSModuleCacheResources.InvalidNameUnderUbuntu -F 'Script module', $file) }; return }
         #'.ni.dll' see PS Core source 'PowerShellNgenAssemblyExtension'
         # Note : "Test.no.dll"' match '.dll'
         { '.ni.dll', '.dll' -eq $_ } { if (-not $isNamingCorrect) { Write-Warning ($PSModuleCacheResources.InvalidNameUnderUbuntu -F 'Binary module', $file) }; return }
         #See use case :https://github.com/PowerShell/PowerShell/issues/6741#issuecomment-385746538
         '.exe' { if (-not $isNamingCorrect) { ($PSModuleCacheResources.InvalidNameUnderUbuntu -F 'Executable', $file) }; return }
         # Windows Powershell only : CDXML (WMI) or .xaml (Workflow).
      }
   }
   return $isNamingCorrect
}

function Confirm-NamingModuleCacheInformation {
   #We test the naming of the files of the primary module and its dependencies.
   param(
      #Name of module to check.
      $ModuleCacheInformation,
      $ModuleSavePath
   )

   $ModuleName = $ModuleCacheInformation.Name
   $Version = $ModuleCacheInformation.Version

   #Regardless of the recovered path (that of Powershell Windows or that of Powershell Core),
   #we check the naming of the files contained in a module directory created by Save-Module
   $isPrimaryModuleCorrect = Test-ModuleNaming -ModuleName $ModuleName -Version $Version -SavePath $ModuleSavePath
   if (-not $isPrimaryModuleCorrect)
   { return $false }

   Foreach ($Dependency in $ModuleCacheInformation.Dependencies) {
      $isDependantModuleCorrect = Test-ModuleNaming -ModuleName $Dependency.Name -Version $Version -SavePath $ModuleSavePath
      if (-not $isDependantModuleCorrect)
      { return $false }
   }
   return $true
}

function Save-ModuleCache {
   <#
.Synopsis
   Called from 'Action.yml'.
   Save the modules, and its dependencies, declared in 'module-to-cache' and 'module-to-cache-prerelease'
   Is Executed only if the cache does not exist (either it has been deleted or it needs to be updated).
#>
   param()

   if (Test-Path env:CI) {
      Write-Output "Existing repositories '$script:RepositoryNames'"
   }
   $ModulesCache = Import-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)

   try {
      Get-PSRepository PSGallery -EA Stop > $null
      Set-PSRepository PSGallery -InstallationPolicy Trusted
   } catch {
      # We give the user the option of not using PSGallery.
      if ($_.CategoryInfo.Category -ne 'ObjectNotFound')
      { throw $_ }
   }

   #Here we save modules and their dependencies, only the 'New-ModuleSavePath' function knows the paths to save in the cache.
   foreach ($ModulePath in $ModulesCache.ModuleSavePaths) {
      foreach ($ModuleCacheInformation in $ModulesCache.ModuleCacheInformations) {
         if (Test-Path env:CI) {
            Write-Output "Saving module '$($ModuleCacheInformation.Name)' version '$($ModuleCacheInformation.Version)' to '$Modulepath'. Search in the following repositories '$($ModuleCacheInformation.Repository)'"
         }

         $parameters = @{
            Name            = $ModuleCacheInformation.Name
            AllowPrerelease = $ModuleCacheInformation.Allowprerelease
            Repository      = $ModuleCacheInformation.Repository
         }

         if ($Null -ne $ModuleCacheInformation.Version) {
            $parameters.Add('RequiredVersion', $ModuleCacheInformation.Version)
         }

         # Save-Module automatically retrieves a module's dependencies from its repository.
         # Save-Module rewrites the version of a module that exists in the directory, it does not test for its presence.
         # If the version is different then Save-Module completes the contents of the directory with the new version.
         Write-Debug "Save-Module -Path $ModulePath -name $($ModuleCacheInformation.Name) -version $($ModuleCacheInformation.Version) -allow $($ModuleCacheInformation.Allowprerelease)  -repo $($ModuleCacheInformation.Repository)"

         Save-Module @Parameters -Path $ModulePath -Force -ErrorAction Stop

         #Once the module and its dependencies are written to disk, we check the naming convention.
         #Changing $WarningPreference in the caller's scope has no impact on this module's scope.
         $null = Confirm-NamingModuleCacheInformation -ModuleCacheInformation $ModuleCacheInformation -ModuleSavePath $ModulePath
      }
   }
}

#endregion
function New-ModuleCacheParameter {
   <#
.Synopsis
  Create an object from GitHub Action parameter values
#>
   param(
      [Parameter(Mandatory = $false, position = 0)]
      [string]$Modules,

      [Parameter(Mandatory = $false, position = 1)]
      [string]$PrereleaseModules,

      [Parameter(Mandatory = $false, position = 2)]
      [string]$Shells,

      [switch]$Updatable,
      [switch]$PrefixIdentifier,
      [bool]$ContainerJob
   )

   if ($script:RepositoryNames.Count -eq 0)
   { throw $PSModuleCacheResources.RegisterAtLeastOneRepository }

   if (($Modules.Trim() -eq [string]::Empty) -and ($PrereleaseModules.Trim() -eq [string]::Empty) )
   { throw $PSModuleCacheResources.MustDefineAtLeastOneModule }

   if ($Shells.Trim() -eq [string]::Empty )
   { throw $PSModuleCacheResources.MustDefineAtLeastOneShell }

   $tab = $Shells.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries)
   [string[]]$tab = $tab | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne [string]::Empty }

   if ($tab.Count -eq 0) {
      throw $PSModuleCacheResources.MustDefineAtLeastOneShell
   }

   [String[]]$Shells = [Linq.Enumerable]::Distinct($tab, [System.StringComparer]::CurrentCultureIgnoreCase)

   $modulecacheparam = [pscustomobject]@{
      PSTypeName                 = 'ModuleCacheParameter';
      ModulesParameter           = $Modules -as [pscustomobject];
      PrereleaseModulesParameter = $PrereleaseModules -as [pscustomobject];
      ShellsParameter            = $Shells -as [pscustomobject];
      CacheType                  = [CacheType]$(if ($Updatable.IsPresent) { [CacheType]::Updatable } else { [CacheType]::Immutable } )
      Updatable                  = $Updatable;
      PrefixIdentifier           = $PrefixIdentifier
      ContainerJob               = $ContainerJob
   }

   $sbToArray = {
      if ($this.Trim() -eq [string]::Empty) {
         , [string[]]@()
      } else {
         , ([string[]]($this.Split(',').Trim()))
      }
   }

   Add-Member -InputObject $modulecacheparam.ModulesParameter -MemberType ScriptMethod -Name ToArray -Value $sbToArray
   $AMParameters = @{
      MemberType  = 'ScriptProperty'
      Name        = 'isCacheContainUpdatableInformation'
      Value       = { $this -match '::' }
      SecondValue = { throw 'IsCacheContainUpdatableInformation is a read only property.' }
   }
   Add-Member -InputObject $modulecacheparam.ModulesParameter @AMParameters

   Add-Member -InputObject $modulecacheparam.PrereleaseModulesParameter -MemberType ScriptMethod -Name ToArray -Value $sbToArray
   Add-Member -InputObject $modulecacheparam.PrereleaseModulesParameter @AMParameters

   $sbIsUpdatable = {
      $this.ModulesParameter.isCacheContainUpdatableInformation -or
      $this.PrereleaseModulesParameter.isCacheContainUpdatableInformation
   }

   Add-Member -InputObject $modulecacheparam -MemberType ScriptProperty -Name isCacheUpdatable -Value $sbIsUpdatable -SecondValue { throw 'isCacheUpdatable is a read only property.' }

   $AMParameters = @{
      MemberType  = 'ScriptProperty'
      Name        = 'IsAuthorizedShells'
      Value       = {
         $MustBeAnAuthorizedShell = [System.Predicate[string]] { param($Name) $Name -match 'pwsh|powershell' }
         return [System.Array]::TrueForAll($this, $MustBeAnAuthorizedShell)
      }
      SecondValue = { throw 'IsAuthorizedShells is a read only property.' }
   }
   Add-Member -InputObject $modulecacheparam.ShellsParameter @AMParameters

   return $modulecacheparam
}

$parms = @{
   Function = 'New-ModuleCacheParameter', 'Find-ModuleCacheName', 'Get-ModuleCache', 'Get-ModuleSavePath', 'New-ModuleSavePath', 'Save-ModuleCache', 'ConvertTo-YamlLineBreak'
   Variable = 'CacheFileName', 'RepositoryNames', 'PsWindowsModulePath', 'PsWindowsCoreModulePath', 'PsLinuxCoreModulePath'
}
Export-ModuleMember @parms