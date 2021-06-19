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
      Write-Output "$env:RUNNER_OS-4-$platform-$($versiontable.PSVersion)-$($Module -join '-')"
   }
   'ModulePath' {
      Write-Output ($env:PSModulePath.Split(";").Split(":") | Select-Object -First 1)
   }
}