param (
   [string[]]$Module,
   [switch]$List
)
$neededlist = @()
$paths = @()

foreach ($item in $module) {
   if ($List) {
      Write-Warning "list"
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
if ($List) {
   #Write-Output "$($neededlist -join ', ')"
   Write-Output "list"
}
else {
   #Write-Output $($paths -join ', ')
   Write-Output "path"
}