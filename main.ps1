param (
   [string[]]$Module,
   [string]$Type
)

$neededlist = @()
foreach ($item in $module) {
   if (-not (Get-Module $item -ListAvailable)) {
      $neededlist += $item
   }
}
switch ($Type) {
   'Needed' {
      Write-Warning "$($neededlist -join ', ')"
      Write-Output "$($neededlist -join ', ')"
   }
   'KeyGen' {
      if ($neededlist.count -gt 0) {
         Write-Output "$($neededlist -join '-')"
      }
      else {
         Write-Output "psmodulecache"
      }
   }
   'ModulePath' {
      Write-Output "/home/runner/.local/share/powershell/Modules/"
      if ($runner.os) {
         Write-Warning $runner.os
      }
   }
}