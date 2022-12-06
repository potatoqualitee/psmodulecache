
#The tests depend on the version of the Runner its image is regularly updated.
if (-not (Test-Path env:CI) ) {
    $env:RUNNER_OS = 'Windows'
    $env:GITHUB_WORKFLOW = 'WorkflowDemo'
    If ( (Test-Path Variable:isWindows) -eq $false) {
        #ps v5.1 only for Windows OS
        $global:isWindows = $true
    }
}

$Configuration = New-PesterConfiguration

#$Configuration.filter.Tag=('shell') #('keygen','ModulePath','PrefixIdentifier','PowershellGetVersion')


$Configuration.Output.Verbosity = 'Detailed'

#The response time of a call to Find-Module on PSGallery can be degraded (between 30 and 60 seconds), where Myget responds between 3 and 6 seconds.
Invoke-Pester -Configuration $Configuration
