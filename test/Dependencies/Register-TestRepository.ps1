
Function New-ModulePublication {
    param(
        [Parameter(Mandatory = $True, position = 0)]
        $Name,

        [Parameter(position = 1)]
        $RequiredVersion,

        $Repository = 'PSModuleCache',

        [Switch]$AllowPrerelease
    )

    @{
        Name            = $Name;
        Repository      = $Repository;
        RequiredVersion = $RequiredVersion;
        AllowPrerelease = $AllowPrerelease.isPresent;
    }
}
Function Test-PsRepository {
    param ([String] $RepositoryName)
    try {
        Get-PSRepository -Name $RepositoryName -EA Stop > $null
        $True
    } catch {
        $False
    }
}

$CloudsmithRepositoryName = 'psmodulecache'
$CloudsmithUriLocation = 'https://nuget.cloudsmith.io/psmodulecache/test/v2/'

#$CloudsmithPrivateUriLocation = 'https://nuget.cloudsmith.io/psmodulecache/privatepsmodulecache/v2/'

$RemoteRepositories = @(
    [PsCustomObject]@{
        name            = 'OttoMatt'
        publishlocation = 'https://www.myget.org/F/ottomatt/api/v2/package'
        sourcelocation  = 'https://www.myget.org/F/ottomatt/api/v2'
    },

    [PsCustomObject]@{
        name            = $CloudsmithRepositoryName
        publishlocation = $CloudsmithUriLocation
        sourcelocation  = $CloudsmithUriLocation
    }
)

Try {
    Get-PackageSource PSModuleCache -ErrorAction Stop >$null
} catch {
    if ($_.CategoryInfo.Category -ne 'ObjectNotFound') {
        throw $_
    } else {
        Register-PackageSource -Name $CloudsmithRepositoryName -Location $CloudsmithUriLocation -Trusted -ProviderName NuGet > $null
    }
}

#Register additionnal repositories with credential
# Register-PackageSource -Name $CloudsmithPrivateRepositoryName -Location $CloudsmithPrivateUriLocation -Trusted -Credential $credential -ProviderName NuGet > $null

foreach ($Repository in $RemoteRepositories) {
    $Name = $Repository.Name
    try {
        Get-PSRepository $Name -ErrorAction Stop >$null
    } catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound') {
            throw $_
        } else {
            $Parameters = @{
                Name               = $Name
                SourceLocation     = $Repository.SourceLocation
                PublishLocation    = $Repository.PublishLocation
                InstallationPolicy = 'Trusted'
            }
            Write-Verbose "Register repository '$($Repository.Name)'"
            # An invalid Web Uri is managed by Register-PSRepository
            Register-PSRepository @Parameters  > $null
        }
    }
}
