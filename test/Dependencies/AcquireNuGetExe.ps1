param (
    #from https://github.com/microsoft/automatic-graph-layout/blob/master/GraphLayout/NuGet/AcquireNuGetExe.ps1
    [switch]$Update = $false
)

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

#PSModule.psm1 Download the NuGet.exe from http://nuget.org/NuGet.exe (v2.8.6)
$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" # 21/08/233 - latest= v6.6.1
$destination_path = Join-Path $env:LOCALAPPDATA "NuGetCommandLine"

$targetNugetExe = "$destination_path\nuget.exe"

if ( (!(Test-Path $targetNugetExe)) -or ( $Update ) ) {

    Write-Host "Downloading install NuGet to $destination_path"

    if (!(Test-Path $destination_path)) {
        New-Item -Path $destination_path -ItemType Directory
    }


    if (Test-Path $targetNugetExe) {
        Remove-Item $targetNugetExe
    }

    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
}


Set-Alias nuget $targetNugetExe -Scope Global -Verbose