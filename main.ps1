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
      Write-Output "$($neededlist -join ', ')"
   }
   'KeyGen' {
      if ($neededlist.count -gt 0) {
         Write-Output "$($PSVersionTable.Platform)-$($neededlist -join '-')"
      }
      else {
         Write-Output "psmodulecache"
      }
   }
   'ModulePath' {
      if ($PSVersionTable.Platform -eq "Win32NT") {
         Write-Output "C:\users\runner\.local\share\powershell\Modules\"
      } else {
         Write-Output "/home/runner/.local/share/powershell/Modules/"
      }
   }
}