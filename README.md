# psmodulecache

This action makes caching PowerShell modules from the PowerShll Gallery easy. Basically, it builds all of the required input for [actions/cache@v2](https://github.com/actions/cache).

## Documentation

Just copy the below code and modify the line `modules-to-cache: 'PSFramework, Pester, dbatools'`

Once GitHub supports [using actions in composite actions](https://github.com/actions/runner/issues/646), there will be a lot less code (just the `Set required PowerShell modules` section). But until then, here's a sample workflow.

```yaml
    - name: Set required PowerShell modules
      id: psmodulecache-action-id
      uses: potatoqualitee/psmodulecache@v0.0.2
      with:
        modules-to-cache: 'PSFramework, Pester, dbatools'
    - name: Setup PowerShell module cache
      id: cache-psmodulesupdate
      uses: actions/cache@v2
      with:
          path: ${{ steps.psmodulecache-action-id.outputs.paths }}
          key: ${{ runner.os }}-psmodulesupdate
    - name: Install required PowerShell modules
      if: steps.cache-psmodulesupdate.outputs.cache-hit != 'true'
      shell: pwsh
      run: |
          Install-Module ${{ steps.psmodulecache-action-id.outputs.needed }} -ErrorAction Stop
```

## Usage

### Pre-requisites
Create a workflow `.yml` file in your repositories `.github/workflows` directory. An [example workflow](#example-workflow) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

### Inputs

* `modules-to-cache` - A comma separated list of PowerShell modules to install or cache. 

### Outputs

None

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
      uses: potatoqualitee/psmodulecache@v0.0.2
      with:
        modules-to-cache: 'PSFramework, Pester, dbatools'

    - name: Setup PowerShell module cache
      id: cache-psmodulesupdate
      uses: actions/cache@v2
      with:
          path: ${{ steps.psmodulecache-action-id.outputs.paths }}
          key: ${{ runner.os }}-psmodulesupdate
    - name: Install required PowerShell modules
      if: steps.cache-psmodulesupdate.outputs.cache-hit != 'true'
      shell: pwsh
      run: |
          Install-Module ${{ steps.psmodulecache-action-id.outputs.needed }} -ErrorAction Stop
```

## Cache Limits

A repository can have up to 5GB of caches. Once the 5GB limit is reached, older caches will be evicted based on when the cache was last accessed.  Caches that are not accessed within the last week will also be evicted.

## Contributing
Pull requests are welcome!

## License
The scripts and documentation in this project are released under the [MIT License](LICENSE)