param (
   [string[]]$Module,
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
         $os = $versiontable.OS.Replace(' ','').Replace('#','')
         $platform = $versiontable.Platform
      } else {
         $os = $platform = "Windows"
      }
      Write-Output "$os-$platform-$($versiontable.PSVersion)-$($Module -join '-')"
   }
   'ModulePath' {
      Write-Output ($env:PSModulePath.Split(";") | Select-Object -First 1)
   }
}