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
      Write-Output "$env:RUNNER_OS-test1-$platform-$($versiontable.PSVersion)-$($Module -join '-')"
   }
   'ModulePath' {
      if ($env:RUNNER_OS -eq "Windows") {
         $modpath = ($env:PSModulePath.Split(";") | Select-Object -First 1)
         if ($ShellToUse -eq "powershell") {
            $modpath = $modpath.Replace("PowerShell","WindowsPowerShell")
         }
         Write-Output $modpath
      } else {
         Write-Output ($env:PSModulePath.Split(":") | Select-Object -First 1)
      }
   }
}