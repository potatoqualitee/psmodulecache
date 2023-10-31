
$CloudsmithRepositoryName = 'psmodulecache'
#$CloudsmithPrivateRepositoryName
$MyGet = @('OttoMatt')

$RemoteRepositories = @($CloudsmithRepositoryName, $MyGet)

foreach ($Name in $RemoteRepositories) {
    Write-Verbose "Unregister repository '$Name'"
    Unregister-PSRepository -Name $Name  > $null
}
