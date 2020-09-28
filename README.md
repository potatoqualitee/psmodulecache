# psmodulecache

This action makes caching PowerShell modules from the PowerShll Gallery easy. Basically, it builds all of the required input for [actions/cache@v2](https://github.com/actions/cache).

## Documentation

Just copy the below code and modify the line `modules-to-cache: 'PSFramework, Pester, dbatools'`

Once GitHub supports [using actions in composite actions](https://github.com/actions/runner/issues/646), there will be a lot less code (just the `Set required PowerShell modules` section). But until then, here's a sample workflow.

```yaml
    - name: Set required PowerShell modules
      id: psmodulecache-action-id
      uses: potatoqualitee/psmodulecache@v1
      with:
        modules-to-cache: 'PSFramework, Pester, dbatools'
    - name: Setup PowerShell module cache
      id: psmodulecache-cacher
      uses: actions/cache@v2
      with:
          path: ${{ steps.psmodulecache-action-id.outputs.modulepath }}
          key: ${{ steps.psmodulecache-action-id.outputs.keygen }}
    - name: Install required PowerShell modules
      if: steps.psmodulecache-cacher.outputs.cache-hit != 'true'
      shell: pwsh
      run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module ${{ steps.psmodulecache-action-id.outputs.needed }} -ErrorAction Stop
```

## Usage

### Pre-requisites
Create a workflow `.yml` file in your repositories `.github/workflows` directory. An [example workflow](#example-workflow) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

### Inputs

* `modules-to-cache` - A comma separated list of PowerShell modules to install or cache

### Outputs

* `needed` - All modules that need to be installed (some are already built-in, like Pester)
* `keygen` - Auto-generated cache key for actions/cache@v2 based on OS and needed modules
* `modulepath` - The PowerShell module path directory
* `modules-to-cache` - A comma separated list of PowerShell modules to install or cache which can be used to confirm that the modules have been installed

### Cache scopes
The cache is scoped to the key and branch. The default branch cache is available to other branches. 

### Example workflow

```yaml
on: [push]

jobs:
  sample-job:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set required PowerShell modules
      id: psmodulecache-action-id
      uses: potatoqualitee/psmodulecache@v1
      with:
        modules-to-cache: 'PSFramework, Pester, dbatools'
    - name: Setup PowerShell module cache
      id: psmodulecache-cacher
      uses: actions/cache@v2
      with:
          path: ${{ steps.psmodulecache-action-id.outputs.modulepath }}
          key: ${{ steps.psmodulecache-action-id.outputs.keygen }}
    - name: Install required PowerShell modules
      if: steps.psmodulecache-cacher.outputs.cache-hit != 'true'
      shell: pwsh
      run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module ${{ steps.psmodulecache-action-id.outputs.needed }} -ErrorAction Stop
    - name: Show that the Action works
      shell: pwsh
      run: |
          Get-Module -Name ${{ steps.psmodulecache-action-id.outputs.modules-to-cache }} -ListAvailable | Select Name
```

## Cache Limits
A repository can have up to 5GB of caches. Once the 5GB limit is reached, older caches will be evicted based on when the cache was last accessed.  Caches that are not accessed within the last week will also be evicted.

## Contributing
Pull requests are welcome!

## TODO
* Add support for specific module versions
* Add support for additional custom repositories (may be out of scope?)
* Once GitHub supports actions in composite actions, only the following will be required!

```yaml
    - name: Set required PowerShell modules
      id: psmodulecache-action-id
      uses: potatoqualitee/psmodulecache@v1
      with:
        modules-to-cache: 'PSFramework, Pester, dbatools'
```

## License
The scripts and documentation in this project are released under the [MIT License](LICENSE)
