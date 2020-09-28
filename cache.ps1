param (
   [string[]]$Module,
   [string]$Type
)

$neededlist = @()
foreach ($item in $module) {
   if ($Type -eq "Needed") {
      if (-not (Get-Module $item -ListAvailable)) {
         $neededlist += $item
      }
   }
}
switch ($Type) {
   'Needed' {
      Write-Warning "$($neededlist -join ', ')"
      Write-Output "$($neededlist -join ', ')"
   }
   'KeyGen' {
      $os = $PSVersionTable.OS.Replace(" ", "-")
      if ($neededlist.count -gt 0) {
         Write-Output "$os-$($neededlist -join '-')"
      } else {
         Write-Output $os
      }
      Write-Warning $os
   }
   'ModulePath' {
      Write-Output "/home/runner/.local/share/powershell/Modules/"
      if ($runner.os) {
         Write-Warning $runner.os
      }
   }
}