param (
   [string[]]$Module,
   [ValidateSet("KeyGen","ModulePath")]
   [string]$Type,
   [ValidateSet("pwsh","powershell")]
   [string]$ShellToUse
)

switch ($Type) {
   'KeyGen' {
      if ($ShellToUse -eq "powershell" -and $PSVersionTable.Platform -eq "Win32NT") {
         $versiontable = Invoke-Command -ScriptBlock { 
            powershell -command { $PSVersionTable } 
         }
      } else {
         $versiontable = $PSVersionTable
      }
      if ($versiontable.OS) {
         $platform = $versiontable.Platform
      } else {
         $platform = "Windows"
      }
      Write-Output "$env:RUNNER_OS-$platform-$($versiontable.PSVersion)-$($Module -join '-')"
   }
   'ModulePath' {
      if ($env:RUNNER_OS -eq "Windows") {
         Write-Output ($env:PSModulePath.Split(";") | Select-Object -First 1)
      } else {
         Write-Output ($env:PSModulePath.Split(":") | Select-Object -First 1)
      }
      Write-Warning ($env:PSModulePath.Split(";") | Select-Object -First 1)
   }
}