# psmodulecache

This action makes caching PowerShell modules from the PowerShell Gallery easy for Linux, Windows and macOS runners. Basically, it builds all of the required input for [actions/cache](https://github.com/actions/cache).

If you're using GitHub Actions to test projects that rely on PowerShell modules like PSFramework or dbatools, this caches those modules so they aren't downloaded from the PowerShell Gallery over and over again.
It is possible to configure a cache with an automatic update, the module search can target in PSGallery or other PSRepositories requiring or not credential.

> **Warning**
> GitHub will [deprecate](https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/) all versions of this Action earlier than v5.1 on June 1, 2023. It is recommended that you update all of your workflows now to use psmodulecache@v5.1 or greater.

## Table of Contents

1. [How to use it](#howto)
2. [Usage](#usage)
3. [Parameters syntax](#parameterssyntax)
4. [Error message](#errormessage)
5. [Examples of settings](#examples)
    1. [Using pwsh on Ubuntu](#example1)
    2. [Using powershell on Windows. pwsh also works and is the default](#example2)
    3. [Install for both powershell and pwsh on Windows](#example3)
    4. [Install a module with a required version, using powershell on Windows](#example4)
    5. [Install a module with an automatic version update, using pswh on MacOS](#example5)
    6. [Using powershell on Windows](#example6)
6. [Cache key construction method](#buildcachekey)
7. [Cache limits](#cachelimits)
8. [Acceptance of a license](#acceptancelicense)
9. [Known issues](#knownissues)

## How to use it <a name="howto"></a>

Just copy the code below and modify the line **`modules-to-cache: PSFramework, PoshRSJob, dbatools`** with the modules you need.

```yaml
    - name: Install and cache PowerShell modules
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSFramework, PoshRSJob, dbatools
```

_PSModuleCache returns the newest version of a module if no parameters are used that limit the version._

If you need to use `RequiredVersion`, add a colon then the version: **`modules-to-cache: PSFramework, dbatools:1.1.0`**

```yaml
    - name: Install and cache PowerShell modules
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSFramework, dbatools:1.1.0
```

For a cache with an update search each time your Action is executed, add two colon: **`modules-to-cache: PSFramework, Pester::, "dbatools::"`**

In this case set the updatable parameter to true.

```yaml
    - name: Install and cache PowerShell modules
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSFramework,Pester::, dbatools:1.1.0
        updatable: true
```

If you need to install a prerelease, use the `modules-to-cache-prerelease` parameter : **`modules-to-cache-prerelease: PnP.PowerShell:1.11.44-nightly`**

```yaml
    - name: Install and cache PowerShell modules
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSFramework,Pester:4.10.1, dbatools:1.1.0
        modules-to-cache-prerelease: PnP.PowerShell:1.11.44-nightly
```

Note:
Under Windows Powershell if the module targets both versions of Powershell, then PSCore uses the path of Powershell v5.1.

It is therefore not necessary to create an installation (a Step) for each version of Powershell.

On the other hand under Windows with PS Core the same module targeting two versions will be only installed in the specific directory of PS Core.

## Usage <a name="usage"></a>

### Pre-requisites

Create a workflow `.yml` file in your repositories `.github/workflows` directory. [Example workflows](#examples) are available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

### Cache scopes

The cache is scoped to the key and branch. The default branch cache is available to other branches.

### Inputs

* `modules-to-cache` - A comma-separated list of PowerShell module names to install and then cache. Each module name can specify a version or auto-update.
A module name can be prefixed with a repository name separated by a backslash.
* `modules-to-cache-prerelease` -A comma-separated list of PowerShell module names marked as a prerelease, to install and then cache. Each module name can specify a version or auto-update.
A module name can be prefixed with a repository name separated by a backslash. **Keep in mind that when searching for a prerelease 'Find-Module' may return a stable version.**

* `shell` - The default shell you'll be using. Defaults to _pwsh_. Recognized shells are '_powershell_' and '_pwsh_', you can specify one or the other, or both.
  Duplicate shell names are silently removed and therefore do not generate an error.
  The use of shell names allows to configure the installation path of the module :

  * For Windows Powershell : _$env:ProgramFiles\WindowsPowerShell\Modules_
  * For Powershell Core (under Windows) : _$env:ProgramFiles\PowerShell\Modules_
  * For Powerhsell Core (under Linux or MacOS) : _/usr/local/share/powershell/Modules/_

* `updatable` - Triggers, on each execution of the action, an update for the module names that request it. Defaults to false.
* `prefixidentifier` - Prefixes the cache key name with the Workflow name ($env:GITHUB_WORKFLOW). Used to group cache keys. Defaults to false.

### Prerelease module versions

The following text details the rule for building a prerelease version number.
[Prerelease module versions](https://learn.microsoft.com/en-us/powershell/scripting/gallery/concepts/module-prerelease-support?view=powershell-5.1)

### Search in repositories

The modules indicated in the _`modules-to-cache'_ or _'modules-to-cache-prerelease'_ parameter can come from PsRepositories declared in the Runner (server).

To declare PsRepositories again, you must save them before calling the 'Cache' step :

```yml
      - name: Setting additional PSRepositories
        shell: pwsh
        run: |
            Register-PSRepository -Name 'OttoMatt' -publishlocation='https://www.myget.org/F/ottomatt/api/v2/package' -sourcelocation='https://www.myget.org/F/ottomatt/api/v2' -InstallationPolicy 'trusted'

      - name: Cache modules
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v6.0
        with:
           modules-to-cache: InvokeBuild,OptimizationRules
           ....
```

The '_OptimizationRules_' module is not published on PSGallery but on [MyGet](https://www.myget.org/feed/ottomatt/package/nuget/OptimizationRules).

#### Note

In the event of multiple presence of the same module name in many repositories, psmodulecache will raise an error.
The use of the following syntax will be necessary to specify from which repository the module is retrieved:

```yml
      - name: Cache modules
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v6.0
        with:
           modules-to-cache: InvokeBuild,OttoMatt\OptimizationRules
           ....
```

The syntax 'OttoMatt\OptimizationRules is nammed _'Repository qualified module name'_.

## Parameters syntax <a name="parameterssyntax"></a>

### Syntax for 'modules-to-cache' parameter

#### InvokeBuild

Simple module name, we save the last stable version found. For this syntax, we do not specify a version number.

The cache content for this module is not updated until the cache lifetime has expired. An Updatable cache will force its update.

#### InvokeBuild:5.0.0

A simple module name followed by a single colon and a three-part version number (mandatory), the requested stable version is recorded.

The cache content for this module will always be the same, regardless of the cache lifetime.

#### PnP.PowerShell&colon;&colon;

Simple module name followed by two colons. For this syntax, we do not specify a version number. The last stable version found is saved.

An update search is started each time your Action is executed.

The cache content is updated as soon as a new version is released or the cache lifetime has expired.

Note : YAML may need to use double quotation marks: **`modules-to-cache: "Pester::"`**

### Syntax for 'modules-to-cache-prerelease' parameter

The syntax is the same as for the _'module-to-cache'_ parameter but concerns only prerelease versions.

#### Pester

Simple module name, we save the last prerelease version found. For this syntax, we do not specify a version number.

The cache content for this module is not updated until the cache lifetime has expired. An Updatable cache will force its update.

#### PnP.PowerShell:1.11.22-nightly

A simple module name followed by a single colon and a four-part version number (mandatory), the requested prerelease is saved.

The cache content for this module will always be the same, regardless of the cache lifetime.

#### PSScriptAnalyzer&colon;&colon;

Simple module name followed by two colons. For this syntax, we do not specify a version number. The last prerelease found is saved **or the latest stable version if there is no prerelease or if the latest stable version is greater than the last published prerelease**.

An update search is started each time your Action is executed.

The cache content is updated as soon as a new prerelease is released or the cache lifetime has expired.

Note : YAML may need to use double quotation marks: **`modules-to-cache-prerelease: "Pester::"`**

#### Get a stable version and a prerelease version of a module

We may want to install a stable version and the last prerelease :

```yaml
modules-to-cache: PnP.PowerShell:1.11.0
modules-to-cache-prerelease: PnP.PowerShell
```

Or a previous version and the latest version :

`modules-to-cache: PnP.PowerShell:1.10.0,PnP.PowerShell`

You can also force the update for prereleases :

```yaml
modules-to-cache: PnP.PowerShell:1.11.0
modules-to-cache-prerelease: "PnP.PowerShell::"
```

Note : YAML may need to use double quotation marks: **`modules-to-cache: "Pester::"`**
The syntax _`modules-to-cache: Pester::`_ will cause a YAML syntax error.

#### Duplicate module name

There can be no module name duplication in _'modules-to-cache'_ or _'modules-to-cache-prerelease'_.
There is no check on grouping module names present in _'modules-to-cache'_ and in _'modules-to-cache-prerelease'_.
Some cases will be filtered before call _Save-Module_, this ensures, when creating the cache, that a module of the same version is not saved several times.
The module name duplication check is case insensitive.

We consider the combination _'InvokeBuild,InvokeBuild::'_ as identical to _'InvokeBuild,InvokeBuild'_. In this case, internally, the final setting will be equal to:

```yaml
modules-to-cache: "InvokeBuild::"
```

For the _'RepositoryName\ModuleName'_ syntax, if there is only one repository and the repository name part is identical,
we consider _'PsGallery\Pester,Pester'_ to be identical to:

```yaml
modules-to-cache: "Pester"
```

If there are several repositories, module version duplication will be tested before saving the path names (ModuleName\Version).

#### Error message <a name="errormessage"></a>

GitHub Action stop a step as soon as [an error is triggered](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#exit-codes-and-error-action-preference).

**The creation of a cache is effective if there was no error during the execution of the workflow**.

Before stopping the processing, we analyze all modules informations.

Syntax errors or incorrect parameter values will be displayed, followed by an exception.

#### Notes

* The following setting:

```yaml
modules-to-cache: "UnknownModule"
shell: powershell, pwsh
```

Generates two identical errors, one for each shell.

* Duplicate shell names are silently removed and therefore do not generate an error:

```yaml
modules-to-cache: "PSScriptAnalyzer"
shell:powershell,pwsh,pwsh,Powershell
```

* The following error is thrown:

_Find-Package: No match was found for the specified search criteria and the updatable module name 'MyModule' (repositories 'PSGallery')._

When

* the module name does not exist in the configured repositories,
* the requested version does not exist in the configured repositories,
* the URI of one of the configured repositories is wrong.

## Examples of settings <a name="examples"></a>

### Using pwsh on Ubuntu <a name="example1"></a>

For these modules, the cache will contain the current versions when the cache is created.

The contents of the cache will be identical as long as its retention period is not exceeded. It may be different during its next creation.

```yaml
on: [push]

jobs:
  run-on-linux:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4.1.0
    - name: Install and cache PowerShell modules
      id: psmodulecache
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSFramework, PoshRSJob
    - name: Show that the Action works
      shell: pwsh
      run: |
          Get-Module -Name PSFramework, PoshRSJob -ListAvailable | Select Path
```

### Using powershell on Windows. pwsh also works and is the default <a name="example2"></a>

For these modules, the cache will contain the current versions when the cache is created.

The contents of the cache will be identical as long as its retention period is not exceeded. It may be different during its next creation.

```yaml
on: [push]

jobs:
  run-on-windows:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v4.1.0
    - name: Install and cache PowerShell modules
      id: psmodulecache
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSFramework, PoshRSJob
    - name: Show that the Action works
      shell: powershell
      run: |
          Get-Module -Name PSFramework, PoshRSJob -ListAvailable | Select Path
          Import-Module PSFramework
```

### Install for both powershell and pwsh on Windows <a name="example3"></a>

For these modules, the cache will contain the current versions when the cache is created.

The contents of the cache will be identical as long as its retention period is not exceeded. It may be different during its next creation.

```yaml
on: [push]

jobs:
  run-for-both-pwsh-and-powershell:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4.1.0
      - name: Install and cache PowerShell modules
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v6.0
        with:
          modules-to-cache: PoshRSJob, dbatools
          shell: powershell, pwsh
      - name: Show that the Action works on pwsh
        shell: pwsh
        run: |
          Get-Module -Name PoshRSJob -ListAvailable | Select Path
          Import-Module PoshRSJob
      - name: Show that the Action works on PowerShell
        shell: powershell
        run: |
          Get-Module -Name PoshRSJob, dbatools -ListAvailable | Select Path
          Import-Module PoshRSJob
```

### Install a module with a required version, using powershell on Windows <a name="example4"></a>

For this module, the cache will always contain this version.

The cache content will be identical regardless of creation cycles due to retention period exceeded.

```yaml
on: [push]

jobs:
  run-for-powershell-on-windows-with-required-version:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4.1.0
      - name: Install a module with a required version
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v6.0
        with:
          modules-to-cache: dbatools:1.0.0
          shell: powershell
      - name: Show that the Action works on PowerShell
        shell: powershell
        run: |
          Get-Module -Name dbatools -ListAvailable | Select Path
          Import-Module dbatools
```

### Install a module with an automatic version update, using pswh on MacOS <a name="example5"></a>

For this module, each time the workflow is executed, updates will be checked. The cache will always contain the latest version.

```yaml
on: [push]

jobs:
  run-for-pwsh-on-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4.1.0
      - name: Install a module with a required version
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v6.0
        with:
          modules-to-cache: "dbatools::"
          shell: pwsh
          updatable: "true"
      - name: Show that the Action works on Pwsh
        shell: pwsh
        run: |
          Get-Module -Name dbatools -ListAvailable | Select Path
          Import-Module dbatools
```

### Using powershell on Windows <a name="example6"></a>

In this example, the version of the `Pester` module is fixed, we always use the latest version for the `dbatools` module and the version of the `PSScriptAnalyzer` module does not matter, we use the one available when creating the cache.

```yaml
on: [push]

jobs:
  run-on-windows:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v4.1.0
    - name: Install and cache PowerShell modules
      id: psmodulecache
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: dbatools::,Pester:5.3.3, PSScriptAnalyzer
        shell: powershell
        updatable: "true"
    - name: Show that the Action works
      shell: powershell
      run: |
          Get-Module -Name PSFramework, PoshRSJob -ListAvailable | Select Path
          Import-Module PSFramework
```

## Cache key construction method <a name="buildcachekey"></a>

The key name of a cache is constructed as follows:

* The name and the version of the runner OS: $env:RUNNER_OS,
* the version number of the PSModuleCache action,
* the cache type: Immutable or Updatable,
* the names of the specified shells,
* followed by module names, and version number if requested. The module name can be preceded by a repository name:
    _'MyRepository\MyMmodule:6.4.2'_.
  If given, the content of the 'module-to-cache' parameter is parsed first.

  _Note_: The addition of the version number is done for the following syntaxes: _'Module::' , 'Module:5.3.0-rc1', 'Module:5.3.0'_.
  Only the _'Module'_ syntax does not add a version number, we know that it is the latest version existing at the time of creation of the cache.

Each part is separated by a hyphen character '-'. _Note_ : The presence of the hyphen character in a module name does not create any problems in this context.

When the `prefixidentifier` parameter is present we add at the beginning key name the name of the current Workflow ($env:GITHUB_WORKFLOW).

This allows to find the caches associated with a workflow when using [GitHub Cli](https://cli.github.com/) with [API](https://docs.github.com/en/rest/actions/cache)

```powershell
   #Retrieve the list of the caches
   #We know by extraction the name of the workflow
  $AllCaches=(gh api  -H "Accept: application/vnd.github+json" /repos/$Repo/actions/caches --paginate|ConvertFrom-Json).actions_caches
  Foreach ($Cache in $AllCaches)
  {
    #The 'prefixidentifier' parameter of the psmoduleCache Action must be 'true'
    $WkfName=$Cache.key -replace '^(.*?)-.*$','$1'
    Add-Member -InputObject $Cache -MemberType NoteProperty -Name WorkflowName -Value $wkfName
  }
  $Caches=$AllCaches|Group-Object WorkflowName -AsHashTable
```

## Cache Limits <a name="cachelimits"></a>

A repository can have up to 5GB of caches. Once the 5GB limit is reached, older caches will be evicted based on when the cache was last accessed.  Caches that are not accessed within the last week (7 days) will also be evicted.

## Acceptance of a license <a name="acceptancelicense"></a>

If a module requires acceptance of a license, it is automatically accepted.

## Known issues <a name="knownissues"></a>

* The following setting is allowed:

```yaml
    - name: Known issue
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: Pester:5.3.0
        modules-to-cache-prerelease: Pester:5.3.0-beta1
```

In this case we consider and record both versions but it is the prerelease version which will be saved last in the ".\Pester\5.3.0" directory.

The following setting can also produce the same effect (we assume that at least one stable version exists and that its version number is lower than 2.0.0):

```yaml
    - name: Known issue
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: "WipModule::"
        modules-to-cache-prerelease: WipModule:2.0.0-beta
```

The problem will occur as soon as version 2.0.0 is released.

If we authorize the configuration with the same module of different version but coming from two repositories:

```yaml
    - name: Known issue
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: ProdStableRepository\MyModule:1.0.0
        modules-to-cache-prerelease: "DevPrereleaseRepository\MyModule::"
```

we implicitly authorize the following case:

```yaml
    - name: Known issue
      uses: potatoqualitee/psmodulecache@v6.0
      with:
        modules-to-cache: PSModuleCache\Duplicate,PSGallery\string
```

Here we register two versions of the 'String' module but each package has a different module GUID.
**We let the user check the consistency of what they configure.**

Note : Under Powershell Core this last setting works some times and other times causes an error (caused by PSmoduleCache) ...

* [Module name collision under Linux](https://github.com/potatoqualitee/psmodulecache/issues/54#issuecomment-1740888358).

* The management of external dependencies (_PrivateData.PSData.ExternalModuleDependencies_) is the responsibility of the user.
That is to say that external dependencies must be specified in the settings, regardless of the order of declaration.

## Contributing

Pull requests are welcome! Special thanks to [@LaurentDardenne](https://github.com/LaurentDardenne) for the massive 5.0 rewrite which introduced a ton of features and fixed a several bugs.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
