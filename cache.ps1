param (
   [string[]]$Module,
   [switch]$NeededOnly
)
$neededlist = @()
$paths = @()
foreach ($item in $module) {
   if ($NeededOnly) {
      if (-not (Get-Module $item -ListAvailable)) {
         $neededlist += $item
      }
   }
   else {
      # leftovers, but may be needed in the future
      if (-not (Get-Module $item -ListAvailable)) {
         $paths += "/home/runner/.local/share/powershell/Modules/$item"
      }
   }
}
if ($NeededOnly) {
   Write-Output "$($neededlist -join ', ')"
}
else {
   # leftovers, but may be needed in the future
   Write-Output "$($paths -join '%0A')"
}