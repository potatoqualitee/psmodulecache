param ($Module)
$module = $Module.Split(",")
foreach ($item in $module.Trim()) {
   if (-not (Get-Module $item -ListAvailable)) {
      # Write-Output "/usr/local/share/powershell/Modules/$item"
      Write-Output "/home/runner/.local/share/powershell/Modules/$item"
   }
}