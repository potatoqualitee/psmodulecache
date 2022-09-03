
#The tests depend on the version of the Runner its image is regularly updated.

if (-not (Test-Path env:CI) )
{
    $env:RUNNER_OS='Windows'
    $env:GITHUB_WORKFLOW='WorkflowDemo'
     #ps v5.1
    $global:isWindows=$true
    if ((Test-Path env:CloudsmithAccountName,env:CloudsmithPassword) -contains $false)
    { Throw "The environment variables 'CloudsmithAccountName' and 'CloudsmithPassword' must exist."}
}

$Configuration=New-PesterConfiguration

#('shell','keygen','ModulePath','PrefixIdentifier','Semver','HashtableValidation','ModuleVersion')
#$Configuration.filter.Tag=('ModuleVersion')

$Configuration.Output.Verbosity=('Detailed')
#$Configuration.CodeCoverage.Enabled=$true

#The response time of a call to Find-Module on PSGallery can be degraded (between 30 and 60 seconds), where Myget responds between 3 and 6 seconds.
Invoke-Pester -Configuration $Configuration
