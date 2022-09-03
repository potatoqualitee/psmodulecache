# psmodulecache

This action makes caching PowerShell modules from the PowerShell Gallery easy for Linux, Windows and macOS runners. Basically, it builds all of the required input for [actions/cache@v2](https://github.com/actions/cache).

If you're using GitHub Actions to test projects that rely on PowerShell modules like PSFramework or dbatools, this caches those modules so they aren't downloaded from the PowerShell Gallery over and over again.

## Documentation

Just copy the code below and modify the line **`modules-to-cache: PSFramework, PoshRSJob, dbatools`** with the modules you need.

If you need to use `RequiredVersion`, add a colon then the version: **`modules-to-cache: PSFramework, Pester:4.10.1, dbatools:1.1.0`**

```yaml
    - name: Install and cache PowerShell modules
      uses: potatoqualitee/psmodulecache@v4.5
      with:
        modules-to-cache: PSFramework, PoshRSJob, dbatools
```

## Usage

### Pre-requisites
Create a workflow `.yml` file in your repositories `.github/workflows` directory. [Example workflows](#example-workflows) are available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

### Inputs

* `modules-to-cache` - A comma separated list of PowerShell modules to install or cache.
* `shell` - The default shell you'll be using. Defaults to pwsh. Options are `pwsh`, `powershell` or `pwsh, powershell` for both pwsh and powershell on Windows.
* `allow-prerelease` - Allow prerelease during Save-Module. Defaults to true.
* `force` - Force during Save-Module. Defaults to true.

### Cache scopes
The cache is scoped to the key and branch. The default branch cache is available to other branches. 

### Example workflows

Using pwsh on Ubuntu

```yaml
on: [push]

jobs:
  run-on-linux:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Install and cache PowerShell modules
      id: psmodulecache
      uses: potatoqualitee/psmodulecache@v4.5
      with:
        modules-to-cache: PSFramework, PoshRSJob, dbatools:1.0.0
    - name: Show that the Action works
      shell: pwsh
      run: |
          Get-Module -Name PSFramework, PoshRSJob, dbatools -ListAvailable | Select Path
```

Using powershell on Windows. pwsh also works and is the default.

```yaml
on: [push]

jobs:
  run-on-windows:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v2
    - name: Install and cache PowerShell modules
      id: psmodulecache
      uses: potatoqualitee/psmodulecache@v4.5
      with:
        modules-to-cache: PSFramework, PoshRSJob, dbatools:1.0.0
    - name: Show that the Action works
      shell: pwsh
      run: |
          Get-Module -Name PSFramework, PoshRSJob, dbatools -ListAvailable | Select Path
          Import-Module PSFramework
```

Install for both powershell and pwsh on Windows.

```yaml
on: [push]

jobs:
  run-for-both-pwsh-and-powershell:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install and cache PowerShell modules
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v4.5
        with:
          modules-to-cache: PoshRSJob, dbatools
          shell: powershell, pwsh
      - name: Show that the Action works on pwsh
        shell: pwsh
        run: |
          Get-Module -Name PoshRSJob, dbatools -ListAvailable | Select Path
          Import-Module PoshRSJob
      - name: Show that the Action works on PowerShell
        shell: powershell
        run: |
          Get-Module -Name PoshRSJob, dbatools -ListAvailable | Select Path
          Import-Module PoshRSJob
```

## Cache Limits
A repository can have up to 5GB of caches. Once the 5GB limit is reached, older caches will be evicted based on when the cache was last accessed.  Caches that are not accessed within the last week will also be evicted.

## Contributing
Pull requests are welcome!

## TODO
* Add support for additional custom repositories (may be out of scope?)

## License
The scripts and documentation in this project are released under the [MIT License](LICENSE)
