param ($Module)
$module = $Module.Split(",")
foreach ($item in $module.Trim()) {
   if (-not (Get-Module $item -ListAvailable)) {
      Install-Module $item -Force
   }
}