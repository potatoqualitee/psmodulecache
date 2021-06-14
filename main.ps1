param (
   [string[]]$Module,
   [string]$Type,
   [ValidateSet("pwsh","powershell")]
   [string]$ShellToUse
)

$neededlist = @()
$allmodules = Get-Module -ListAvailable

foreach ($item in $Module) {
   if (-not ($allmodules | Where-Object Name -eq $item)) {
      $neededlist += $item
   }
}
switch ($Type) {
   'Needed' {
      Write-Output "$($neededlist -join ', ')"
   }
   'KeyGen' {
      if ($ShellToUse -eq "powershell" -and $PSVersionTable.Platform -eq "Win32NT") {
         $versiontable = (powershell -command { $PSVersionTable })
      } else {
         $versiontable = $PSVersionTable
      }
      if ($neededlist.count -gt 0) {
         if ($versiontable.OS) {
            $os = $versiontable.OS.Replace(' ','').Replace('#','')
            $platform = $versiontable.Platform
         } else {
            $os = $platform = "Windows"
         }
         Write-Output "$os-$platform-$($versiontable.PSVersion)-$($neededlist -join '-')"
      } else {
         Write-Output "psmodulecache"
      }
   }
   'ModulePath' {
      Write-Output ($env:PSModulePath.Split(";") | Select-Object -First 1)
   }
}