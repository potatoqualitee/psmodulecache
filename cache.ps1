param (
   [string[]]$Module,
   [switch]$NeededOnly
)
$neededlist = @()
$paths = @()
write-warning "$Module"
Write-warning "$NeededOnly"
foreach ($item in $module) {
   if ($NeededOnly) {
      if (-not (Get-Module $item -ListAvailable)) {
         $neededlist += $item
      }
   }
   else {
      if (-not (Get-Module $item -ListAvailable)) {
         $paths += "/home/runner/.local/share/powershell/Modules/$item"
      }
   }
}
if ($NeededOnly) {
   Write-Output "$($neededlist -join ', ')"
}
else {
   Write-Output $($paths -join ', ')
}