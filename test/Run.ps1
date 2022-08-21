
#The tests depend on the version of the Runner its image is regularly updated.

if (-not (Test-Path env:CI) )
{
    $env:RUNNER_OS='Windows'
    $env:GITHUB_WORKFLOW='WorkflowDemo'
     #ps v5.1
    $global:isWindows=$true
}

$Configuration=New-PesterConfiguration

#$Configuration.filter.Tag=('shell') #('keygen','ModulePath','PrefixIdentifier','Semver')

$Configuration.Output.Verbosity=('Detailed')
#$path= Split-Path $PSCommandPath -Parent
#$Configuration.run.path="./Test"
#$Configuration.CodeCoverage.Enabled=$true

#The response time of a call to Find-Module on PSGallery can be degraded (between 30 and 60 seconds), where Myget responds between 3 and 6 seconds.
Invoke-Pester -Configuration $Configuration
