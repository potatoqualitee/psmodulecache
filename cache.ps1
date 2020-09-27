param (
   [string[]]$Module, 
   [switch]$List
)
$neededlist = @()
$paths = @()
$module = $Module.Split(",")

foreach ($item in $module) {
   if ($List) {
      if (-not (Get-Module $item -ListAvailable)) {
         $neededlist += $item
      }
   } else {
      if (-not (Get-Module $item -ListAvailable)) {
         $paths += "/home/runner/.local/share/powershell/Modules/$item"
      }
   }
}
if ($List) {
   Write-Output "$($neededlist -join ', ')"
} else {
   Write-Output "$($paths -join ', ')"
}