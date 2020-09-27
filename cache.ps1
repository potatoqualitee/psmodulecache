param (
   [string]$Module, 
   [switch]$List
)
$module = $Module.Split(",")
$neededlist = @()
$paths = @()
foreach ($item in $module.Trim()) {
   if ($List) {
      if (-not (Get-Module $item -ListAvailable)) {
         $neededlist += $item
      }
   } else {
      if (-not (Get-Module $item -ListAvailable)) {
         # Write-Output "/usr/local/share/powershell/Modules/$item"
         $paths += "/home/runner/.local/share/powershell/Modules/$item"
      }
   }
}
if ($list) {
   $neededlist -join ", "
}
# if no paths, then it shouldn't run the install-module anyway
$paths -join ", "