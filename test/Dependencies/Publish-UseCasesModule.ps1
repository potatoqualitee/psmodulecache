#Publish test modules
# !! Publishing is done outside of a Github Action

Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ApiKey
)

$nugetCommand = Get-Command nuget.exe
if ($null -eq $nugetCommand)
{ throw "Nuget.exe not found. Check the contents of the %Path% variable." }

. "$PSScriptRoot\Register-TestRepository.ps1"

<#
'GUIDNotExist' manifest is invalid, the guid of the RequiredModules 'string' is invalid (it do not exist).

'DependNotExist' manifest use 'Moduleversion' key ('0.0.1'), PSGet use the latest version ('2.0.0')

'External' manifest use external module dependency (nammed 'UnknownModule').


'Tools' 1.0.0 (standalone)
'UpperCase' 1.0.0 (standalone)
'lowercase' 0.0.1 (standalone) manifest is a release version ( manifest file is casesensitive)
'lowercase' 1.0.0-beta (standalone) manifest is a prerelease version ( manifest file is casesensitive)
'lowercase' 2.0.0 (standalone) manifest is a release version ( manifest file is casesensitive)


'String' 1.0.0 module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
  'String' 1.1.0-beta module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
  'String' 1.1.0-alpha module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
  'String' 1.1.0-gamma module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
'String' 2.0.0 module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
'String' 2.1.0-beta module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
'String' 3.0.0 module depend on 'lowercase' module: ModuleVersion = '2.0.0'

Note : 'string' (in lowercase) exist into PSGallery.


'Datas' 1.0.0  module depend on 'Uppercase' and 'Tools' module

'Depends' 1.0.0 manifest use 'RequiredVersion' ('Tools' version 1.0.0)

'Duplicate' 1.0.0 manifest use RequiredVersion ('String' version 1.0.0)
'Example' 1.0.0 manifest use RequiredVersion ('String'; version  2.0.0)

'Main' 1.0.0 manifest use 'ModuleVersion' ('Duplicate' version 1.0.0)
 Note : 'Main' exist into PSGallery.

'DuplicateByDependency' 1.0.0 manifest use 'RequiredVersion' ('Main' version 1.0.0)

'OnlyPrereleaseVersion'   1.0.0-beta (standalone)

'OnlyStableVersion'       1.0.0 (standalone)

'LatestPrereleaseVersion' 1.0.0 module depend on 'Uppercase' module: ModuleVersion = '1.0.0'
'LatestPrereleaseVersion' 2.0.0-beta module depend on 'Uppercase' module: ModuleVersion = '1.0.0'

'LatestStableVersion'     1.0.0-beta (standalone)
'LatestStableVersion'     2.0.0 (standalone)
#>

$script:OrderedModuleNames = @(
    New-ModulePublication 'Tools'
    New-ModulePublication 'UpperCase'
    New-ModulePublication 'Datas'
    New-ModulePublication 'lowercase' '0.0.1'
    New-ModulePublication 'lowercase' '1.0.0' -AllowPrerelease
    New-ModulePublication 'lowercase' '2.0.0'
    New-ModulePublication 'String' '1.0.0'
    New-ModulePublication 'String' '1.1.0' -AllowPrerelease
    #Then we add the following packages 'String.1.1.0-gamma.nupkg' AND 'String.1.1.0-alpha.nupkg'
    New-ModulePublication 'String' '1.1.3'
    New-ModulePublication 'String' '1.3.0' # RequiredModules  with 'MaximumVersion' key
    New-ModulePublication 'String' '2.0.0'
    New-ModulePublication 'String' '2.1.0' -AllowPrerelease
    New-ModulePublication 'String' '3.0.0'
    New-ModulePublication 'Depends'
    New-ModulePublication 'Duplicate'
    New-ModulePublication 'Example'
    New-ModulePublication 'Main'
    New-ModulePublication 'DependNotExist'
    New-ModulePublication 'External'
    New-ModulePublication 'DuplicateByDependency'
    New-ModulePublication 'OnlyStableVersion'
    New-ModulePublication 'OnlyPrereleaseVersion'
    New-ModulePublication 'LatestPrereleaseVersion' '1.0.0'
    New-ModulePublication 'LatestPrereleaseVersion' '2.0.0' -AllowPrerelease
    New-ModulePublication 'LatestStableVersion' '1.0.0' -AllowPrerelease
    New-ModulePublication 'LatestStableVersion' '2.0.0'
)

Function Publish-UseCasesModule {
    $Source = "$PSScriptRoot/Gallery"

    #Needed to find module manifests when publishing
    if ($null -eq $Env:PsModulePath)
    { $Env:PsModulePath = $Source }
    else
    { $Env:PsModulePath += "$([System.IO.Path]::PathSeparator)$Source" }
    Write-Warning "PsModulePath = $Env:PsModulePath"


    $OrderedModuleNames | ForEach-Object {
        $parameters = $_

        Write-Warning "Try to publish '$($Parameters.Name)' $($Parameters.RequiredVersion) in $CloudsmithRepositoryName"
        if ($null -eq $Parameters.RequiredVersion) {
            $parameters.Remove('RequiredVersion')
            $ModulePath = "$Source/$($Parameters.Name)"
        } else {
            $ModulePath = "$Source/$($Parameters.Name)/$($Parameters.RequiredVersion)"
        }
        try {
            Find-Module @Parameters  -Repository $CloudsmithRepositoryName -EA Stop > $null
            Write-Warning "Found"
            $isPublished = $true
        } catch {
            Write-Warning "Not Found"
            $isPublished = $false
        }
        if ($isPublished -eq $false) {
            Write-Warning "Publish"
            try {
                Publish-Module -Repository $CloudsmithRepositoryName -Name $ModulePath -Force  -NuGetApiKey $ApiKey
                Start-Sleep -Seconds 3
                #Publish-Module check the dependencies manifests from local computer
            } catch [System.InvalidOperationException] {
                if ($_.FullyQualifiedErrorId -notmatch '^ModuleVersionIsAlreadyAvailableInTheGallery')
                { throw $_ }
            } catch {
                throw $_
            }
        }
    }
}


#Error on Unbuntu and MacOS:
# The specified RequiredModules entry 'UpperCase' in the module manifest '/tmp/881467654/String/String.psd1' is invalid.
#
#The command  ' Test-ModuleManifest "$source/Datas/1.0.0/Datas.psd1" ' fail
#https://github.com/PowerShell/PowerShell/issues/7722

Publish-UseCasesModule

#To simplify tests code we use Nuget packages

nuget.exe push -Source $CloudsmithUriLocation "$PSScriptRoot/Gallery/String.1.1.0-alpha.nupkg" $ApiKey
nuget.exe push -Source $CloudsmithUriLocation "$PSScriptRoot/Gallery/String.1.1.0-gamma.nupkg" $ApiKey

