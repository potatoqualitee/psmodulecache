#PSModuleCache.psm1
#Requires -Modules @{ ModuleName="powershellget"; ModuleVersion="1.6.6" }

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

$PSModuleCacheResources = Import-PowerShellDataFile "$PsScriptRoot/PSModuleCache.Resources.psd1" -ErrorAction Stop

New-Variable -Name ActionVersion -Option ReadOnly -Scope Script -Value '5.3'

New-Variable -Name Delimiter -Option ReadOnly -Scope Script -Value '-'

#Lists the names of registered repositories, by default PsGallery.
#Additional repositories are added beforehand in a dedicated 'Step'.
New-Variable -Name RepositoryNames -Option ReadOnly -Scope Script -Value @(Get-PSRepository | Select-Object -ExpandProperty Name)

New-Variable -Name PsWindowsModulePath -Option ReadOnly -Scope Script -Value "$env:ProgramFiles\WindowsPowerShell\Modules"
New-Variable -Name PsWindowsCoreModulePath -Option ReadOnly -Scope Script -Value "$env:ProgramFiles\PowerShell\Modules"
New-Variable -Name PsLinuxCoreModulePath -Option ReadOnly -Scope Script -Value '/usr/local/share/powershell/Modules/'

New-Variable -Name CacheFileName -Option ReadOnly -Scope Script -Value 'PSModuleCache.Datas.xml'

#Contains strings detailing syntax rules that are violated in the content of the 'module-to-cache' parameter.
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

function New-ModuleToCacheInformation {
   #creates an object containing the information of a module
   param(
      #Module name
      [Parameter(Mandatory, position = 0)]
      [string]$Name,

      #Versioning management, for this module
      # Allows to build the key for this module (with or without version).
      # Only $Action.Updatable determines the cache type.
      [Parameter(Mandatory, position = 1)]
      [CacheType]$Type,

      #Requested version or an empty string.
      #Can be in [Version] (Powershell v5.1) or [semver] format (Powershell >= v6.0 ) or empty.
      [Parameter(position = 2)]
      [string]$Version,

      #Save either a prerelease version for the module ($true) or a stable version ($false).
      [switch]$AllowPrerelease
   )

   [pscustomobject]@{
      PSTypeName      = 'ModuleToCacheInformation'
      Name            = $Name
      Type            = $Type
      Version         = $Version
      AllowPrerelease = $AllowPrerelease
      ModuleSavePaths = $null
   }
}

function Split-ModuleCacheInformation {
   # Split a string containing versioning information for a module and check the syntax rules.
   # Example: ModuleName or ModuleName:1.0.1 or ModuleName::
   Param(
      $ModuleCacheInformation,
      [switch]$AllowPrerelease
   )

   if ($ModuleCacheInformation -eq [string]::Empty) {
      Add-FunctionnalError -Message ($PSModuleCacheResources.EmptyModuleName -F $ModuleCacheInformation)
      #The processing of the other module information is continued, which makes it possible to list all the syntax errors.
      return
   }

   if ($ModuleCacheInformation -match '^(?<Name>.*?)::(?<Version>.*){0,1}$') {
      #We are looking for the latest version available in the module repository
      $Name = $Matches.Name
      if ($Name -eq [string]::Empty) {
         Add-FunctionnalError -Message ($PSModuleCacheResources.EmptyModuleName -F $ModuleCacheInformation)
         return #In this case the following instructions will fail
      }
      if ($Matches.Version -ne [string]::Empty) {
         Add-FunctionnalError -Message ($PSModuleCacheResources.UpdatableModuleCannotContainVersionInformation -F $ModuleCacheInformation)
         #Here we are not trying to find out if the version text is really a version type.
         return
      }
      #We are looking for the version currently published in the repositories.
      #In case of new version, the cache key changes and will trigger the creation of a new cache.
      $parameters = @{
         Name            = $Name
         AllowPrerelease = $AllowPrerelease
         Repository      = $script:RepositoryNames
      }

      #if there is no prerelease, using AllowPrerelease returns the latest stable release.
      $RepoItemInfo = Find-ModuleCache @Parameters

      if ($null -ne $RepoItemInfo) {
         $Version = $RepoItemInfo.Version
      } else {
         $Version = $null
      }

      $cacheinfo = New-ModuleToCacheInformation -Type 'Updatable' -Name $Name -Version $Version -AllowPrerelease:$AllowPrerelease
   } else {
      #We use the string as it is
      $Name, $Version = $ModuleCacheInformation.Split(':')
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
      $cacheinfo = New-ModuleToCacheInformation -Type 'Immutable' -Name $Name -Version $Version -AllowPrerelease:$AllowPrerelease
   }

   return $cacheinfo
}

function New-ModuleCache {
   #Build a modulecache object from Action parameters.
   param (
      #pscustomobject with pstypename 'ModuleCacheParameter'
      $Action
   )

   function New-Key {
      #Either an existing cache key name or a new cache key name is returned.
      #In this case if there is a cache with the old key, the release rule will apply:
      # GitHub will remove any cache entries that have not been accessed in over 7 days.
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
         $ShellsParameter,
         [switch]$AllowPrerelease
      )
      foreach ($module in $modules) {
         #Check syntax rules
         $cacheinfo = Split-ModuleCacheInformation -ModuleCacheInformation $module -AllowPrerelease:$AllowPrerelease

         if ($null -ne $cacheinfo) {
            #To save a module, we use the PSModulePath associated with the shells,the module name and the version (not a semver).
            $cacheinfo.ModuleSavePaths = Get-ModuleSavePath -ContainerJob $ContainerJob -Shells $ShellsParameter
         }
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

   $StableModules = $Action.ModulesParameter.ToArray()
   $PrereleaseModules = $Action.PrereleaseModulesParameter.ToArray()

   $ModuleCacheInformations = @(
      Split-ModuleParameter -ContainerJob $Action.ContainerJob -modules $StableModules -ShellsParameter $Action.ShellsParameter
      Split-ModuleParameter -ContainerJob $Action.ContainerJob -modules $PrereleaseModules -ShellsParameter $Action.ShellsParameter -AllowPrerelease
   )

   #The serialization depth use default value 2
   return  [pscustomobject]@{
      PSTypeName              = 'ModuleCache'
      Key                     = Join-ModuleName
      ModuleCacheInformations = $ModuleCacheInformations
      PrefixIdentifier        = $Action.PrefixIdentifier
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
   return one or more module full paths
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
   return one or more module full paths.
   Modify the case of the module name if necessary.
   Called from Action.yml
#>
   param( $modulecacheinfo )

   $parameters = @{
      Name            = $null
      AllowPrerelease = $null
      Repository      = $script:RepositoryNames
   }

   foreach ($cacheinfo in $modulecacheinfo) {

      $parameters.Name = $cacheinfo.Name
      $parameters.AllowPrerelease = $cacheinfo.Allowprerelease

      #If it exists, we use the Nuget package name which is case sensitive.
      #Otherwise we keep the name received, it will be tested during the second pass ( Save-ModuleCache )
      $NugetPackage = Find-ModuleCacheName @parameters
      if ($null -eq $NugetPackage)
      { $ModuleName = $cacheinfo.Name }
      else {
         Write-Warning "For the module name '$($cacheinfo.Name)' we use the case of the nuget package name: '$($NugetPackage.Name)'"
         $ModuleName = $NugetPackage.Name
         $cacheinfo.Name = $NugetPackage.Name
      }

      # For the management of a new version in the directory of an EXISTING module (see the image of the runner)
      # the new version number is added to the name of the save path, if it is specified.
      # We manage the following cases:
      #     'ModuleName::' , 'ModuleName:5.3.0-rc1', 'ModuleName:5.3.0'
      #
      # But we do not manage the following case: 'ModuleName'
      $Version = $cacheinfo.Version
      $isVersion = $Version -ne [String]::Empty

      if ($isVersion) {
         #Adapting the version number for the call of Save-Module cmdlet.
         $Version = ConvertTo-Version $Version
      }

      foreach ($ModuleSavePath in $cacheinfo.ModuleSavePaths) {
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
   <#
.Synopsis
   Convert an array of string to a unique YAML string.
#>
   param ($Collection)
   #https://github.com/orgs/community/discussions/26288

   $ofs = '%0A' #https://yaml.org/spec/1.2.2/#54-line-break-characters
   return "$Collection"
}

function Find-ModuleCacheName {
   #Fnd the module package name.
   #On linux, the module name used to build the path, save-module, is that of the Nuget package and not the 'modules-to-cache' parameter.
   #So you can have case-based name differences.

   #if a module name is present in several repositories we sort the elements by version number then we select the first of the list.
   #note : Find-Module returns the newest version of a module if no parameters are used that limit the version.
   [CmdletBinding()]
   param(
      $Name,
      $Repository,
      $RequiredVersion,
      [switch]$AllowPrerelease
   )
   try {
      Find-Module @PSBoundParameters -ErrorAction Stop |
      Sort-Object Version -Descending |
      Select-Object -First 1
   } catch [System.Exception] {
      return $null
   }
}

function Find-ModuleCache {
   #if a module name is present in several repositories we sort the elements by version number then we select the first of the list.
   #note : Find-Module returns the newest version of a module if no parameters are used that limit the version.
   [CmdletBinding()]
   param(
      $Name,
      $Repository,
      $RequiredVersion,
      [switch]$AllowPrerelease
   )
   try {
      Find-Module @PSBoundParameters -ErrorAction Stop |
      Sort-Object Version -Descending |
      Select-Object -First 1
   } catch [System.Exception] {
      #Same exception for cases where the module does not exist or the requested version does not exist.
      if (($_.CategoryInfo.Category -eq 'ObjectNotFound') -and ($_.FullyQualifiedErrorId -Match '^NoMatchFoundForCriteria')) {
         #if the URI of a repository is wrong, Find-Module generates a warning then an exception.
         # We therefore do not know the real cause of the error.
         Add-FunctionnalError -Message ($PSModuleCacheResources.UnknownModuleName -F $Name, "$RepositoryNames")
         return $null
      } else {
         throw  $_
      }
   }
}
#endregion

#region SaveModule
function Save-ModuleCache {
   <#
.Synopsis
   Called from 'Action.yml'.
   Save the modules declared in 'module-to-cache' and 'module-to-cache-prerelease'
#>

   param()

   if (Test-Path env:CI) {
      Write-Output "Existing repositories '$RepositoryNames'"
   }
   $ModuleCache = Import-Clixml -Path (Join-Path $home -ChildPath $CacheFileName)

   try {
      Get-PSRepository PSGallery -EA Stop > $null
      Set-PSRepository PSGallery -InstallationPolicy Trusted
   } catch {
      if ($_.CategoryInfo.Category -ne 'ObjectNotFound')
      { throw $_ }
   }

   foreach ($ModuleCacheInformation in $ModuleCache.ModuleCacheInformations) {
      foreach ($ModulePath in $ModuleCacheInformation.ModuleSavePaths) {
         if (Test-Path env:CI) {
            Write-Output "Saving module '$($ModuleCacheInformation.Name)' version '$($ModuleCacheInformation.Version)' to '$Modulepath'. Search in the following repositories '$RepositoryNames'"
         }

         $parameters = @{
            Name            = $ModuleCacheInformation.Name
            AllowPrerelease = $ModuleCacheInformation.Allowprerelease
            Repository      = $script:RepositoryNames
         }

         if ($Null -ne $ModuleCacheInformation.Version) {
            $parameters.Add('RequiredVersion', $ModuleCacheInformation.Version)
         }

         $RepoItemInfo = Find-ModuleCache @Parameters
         if ($null -ne $RepoItemInfo) {
            $parameters.Repository = $RepoItemInfo.Repository
            if (Test-Path env:CI)
            { Write-Output ("`tModule '{0}' version '{1}' found in '{2}'." -F $RepoItemInfo.Name, $RepoItemInfo.Version, $RepoItemInfo.Repository) }
            Save-Module @Parameters -Path $ModulePath -Force -ErrorAction Stop
         }
      }
   }
   Test-FunctionnalError
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